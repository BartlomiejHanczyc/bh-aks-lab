namespace LabApi.Models;

public sealed record DailyForecast(
    DateOnly Date,
    TemperatureSummary TemperatureCelsius,
    double PrecipitationProbability,
    double PrecipitationMillimetres,
    double PeakWindSpeedKilometresPerHour);
