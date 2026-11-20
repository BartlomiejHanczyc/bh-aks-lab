using LabApi.Configuration;
using LabApi.Models;
using Microsoft.Extensions.Options;

namespace LabApi.Services;

public sealed class WeatherForecastService(
    IOptions<SimulationOptions> options,
    TimeProvider timeProvider,
    ILogger<WeatherForecastService> logger) : IWeatherForecastService
{
    private const int MinutesPerDay = 1440;
    private const double HoursPerDay = 24.0;
    private const double DaysPerYear = 365.25;
    private const double DegreesPerHour = 15.0;
    private const double WarmestNorthernDayOfYear = 200.0;
    private const double WarmestLocalHour = 15.0;
    private const double DiurnalAmplitude = 4.5;
    private const double TemperaturePersistenceHours = 36.0;
    private const double PressurePersistenceHours = 48.0;
    private const double GustPersistenceHours = 6.0;
    private const double TemperatureSpread = 3.5;
    private const double PressureSpread = 9.0;
    private const double GustSpread = 6.0;
    private const double BaseWindSpeed = 12.0;
    private const double WindPerHectopascal = 0.8;
    private const double CloudCoolingPerHectopascal = 0.15;
    private const double RainPressureThreshold = -6.0;
    private const double RainRatePerHectopascal = 0.06;
    private const double WetDayThresholdMillimetres = 1.0;

    public ForecastResponse GenerateForecast(ForecastRequest request, CancellationToken cancellationToken)
    {
        var timeStepMinutes = options.Value.TimeStepMinutes;
        var stepsPerDay = MinutesPerDay / timeStepMinutes;
        var stepHours = HoursPerDay / stepsPerDay;
        var generatedAt = timeProvider.GetUtcNow();
        var startTimestamp = timeProvider.GetTimestamp();
        var firstDay = DateOnly.FromDateTime(generatedAt.UtcDateTime).AddDays(1);

        var climatology = BuildClimatology(request, firstDay, stepsPerDay, stepHours);
        var accumulators = new DailyAccumulator[request.Days];
        for (var day = 0; day < accumulators.Length; day++)
        {
            accumulators[day] = new DailyAccumulator(request.EnsembleMembers);
        }

        RunEnsemble(request, climatology, accumulators, stepsPerDay, stepHours, cancellationToken);

        var days = new DailyForecast[request.Days];
        for (var day = 0; day < days.Length; day++)
        {
            days[day] = accumulators[day].Summarize(firstDay.AddDays(day));
        }

        var elapsedMilliseconds = timeProvider.GetElapsedTime(startTimestamp).TotalMilliseconds;

        logger.LogInformation(
            "Simulated {EnsembleMembers} ensemble members over {Days} days at ({Latitude}, {Longitude}) in {ElapsedMilliseconds:F1} ms",
            request.EnsembleMembers,
            request.Days,
            request.Latitude,
            request.Longitude,
            elapsedMilliseconds);

        return new ForecastResponse(
            request.Latitude,
            request.Longitude,
            generatedAt,
            request.EnsembleMembers,
            timeStepMinutes,
            Math.Round(elapsedMilliseconds, 1),
            days);
    }

    private static double[] BuildClimatology(ForecastRequest request, DateOnly firstDay, int stepsPerDay, double stepHours)
    {
        var absoluteLatitude = Math.Abs(request.Latitude);
        var annualMean = 28.0 - 0.0065 * absoluteLatitude * absoluteLatitude;
        var seasonalAmplitude = 0.17 * absoluteLatitude;
        var warmestDayOfYear = request.Latitude >= 0
            ? WarmestNorthernDayOfYear
            : WarmestNorthernDayOfYear + DaysPerYear / 2;

        var climatology = new double[request.Days * stepsPerDay];
        for (var day = 0; day < request.Days; day++)
        {
            var dayOfYear = firstDay.AddDays(day).DayOfYear;
            for (var step = 0; step < stepsPerDay; step++)
            {
                var utcHour = step * stepHours;
                var localHour = utcHour + request.Longitude / DegreesPerHour;
                var seasonPhase = (dayOfYear + utcHour / HoursPerDay - warmestDayOfYear) / DaysPerYear;
                var dayPhase = (localHour - WarmestLocalHour) / HoursPerDay;

                climatology[day * stepsPerDay + step] = annualMean
                    + seasonalAmplitude * Math.Cos(Math.Tau * seasonPhase)
                    + DiurnalAmplitude * Math.Cos(Math.Tau * dayPhase);
            }
        }

        return climatology;
    }

    private static void RunEnsemble(
        ForecastRequest request,
        double[] climatology,
        DailyAccumulator[] accumulators,
        int stepsPerDay,
        double stepHours,
        CancellationToken cancellationToken)
    {
        var temperatureDecay = Math.Exp(-stepHours / TemperaturePersistenceHours);
        var pressureDecay = Math.Exp(-stepHours / PressurePersistenceHours);
        var gustDecay = Math.Exp(-stepHours / GustPersistenceHours);
        var temperatureNoise = TemperatureSpread * Math.Sqrt(1.0 - temperatureDecay * temperatureDecay);
        var pressureNoise = PressureSpread * Math.Sqrt(1.0 - pressureDecay * pressureDecay);
        var gustNoise = GustSpread * Math.Sqrt(1.0 - gustDecay * gustDecay);
        var random = new Random();

        for (var member = 0; member < request.EnsembleMembers; member++)
        {
            cancellationToken.ThrowIfCancellationRequested();

            var temperatureAnomaly = 0.0;
            var pressureAnomaly = 0.0;
            var gust = 0.0;

            for (var day = 0; day < request.Days; day++)
            {
                var minimum = double.MaxValue;
                var maximum = double.MinValue;
                var temperatureSum = 0.0;
                var precipitation = 0.0;
                var peakWind = 0.0;
                var offset = day * stepsPerDay;

                for (var step = 0; step < stepsPerDay; step++)
                {
                    temperatureAnomaly = temperatureDecay * temperatureAnomaly + temperatureNoise * NextGaussian(random);
                    pressureAnomaly = pressureDecay * pressureAnomaly + pressureNoise * NextGaussian(random);
                    gust = gustDecay * gust + gustNoise * NextGaussian(random);

                    var depression = Math.Max(0.0, -pressureAnomaly);
                    var temperature = climatology[offset + step] + temperatureAnomaly - CloudCoolingPerHectopascal * depression;
                    var wind = Math.Max(0.0, BaseWindSpeed - WindPerHectopascal * pressureAnomaly + gust);

                    if (pressureAnomaly < RainPressureThreshold)
                    {
                        precipitation += (RainPressureThreshold - pressureAnomaly) * RainRatePerHectopascal * stepHours;
                    }

                    minimum = Math.Min(minimum, temperature);
                    maximum = Math.Max(maximum, temperature);
                    temperatureSum += temperature;
                    peakWind = Math.Max(peakWind, wind);
                }

                accumulators[day].Record(member, minimum, maximum, temperatureSum / stepsPerDay, precipitation, peakWind);
            }
        }
    }

    private static double NextGaussian(Random random)
    {
        var magnitude = Math.Sqrt(-2.0 * Math.Log(1.0 - random.NextDouble()));
        return magnitude * Math.Cos(Math.Tau * random.NextDouble());
    }

    private sealed class DailyAccumulator(int ensembleMembers)
    {
        private readonly double[] _meanTemperatures = new double[ensembleMembers];
        private double _minimumSum;
        private double _maximumSum;
        private double _precipitationSum;
        private double _peakWindSum;
        private int _wetMembers;

        public void Record(int member, double minimum, double maximum, double mean, double precipitation, double peakWind)
        {
            _meanTemperatures[member] = mean;
            _minimumSum += minimum;
            _maximumSum += maximum;
            _precipitationSum += precipitation;
            _peakWindSum += peakWind;

            if (precipitation >= WetDayThresholdMillimetres)
            {
                _wetMembers++;
            }
        }

        public DailyForecast Summarize(DateOnly date)
        {
            var count = _meanTemperatures.Length;
            Array.Sort(_meanTemperatures);

            var temperature = new TemperatureSummary(
                Math.Round(_minimumSum / count, 1),
                Math.Round(_maximumSum / count, 1),
                Math.Round(_meanTemperatures.Average(), 1),
                Math.Round(Percentile(_meanTemperatures, 0.10), 1),
                Math.Round(Percentile(_meanTemperatures, 0.90), 1));

            return new DailyForecast(
                date,
                temperature,
                Math.Round((double)_wetMembers / count, 3),
                Math.Round(_precipitationSum / count, 1),
                Math.Round(_peakWindSum / count, 1));
        }

        private static double Percentile(double[] sorted, double fraction)
        {
            var position = fraction * (sorted.Length - 1);
            var lower = (int)position;
            var upper = Math.Min(lower + 1, sorted.Length - 1);
            return sorted[lower] + (sorted[upper] - sorted[lower]) * (position - lower);
        }
    }
}
