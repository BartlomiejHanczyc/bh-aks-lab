using LabApi.Models;

namespace LabApi.Services;

public interface IWeatherForecastService
{
    ForecastResponse GenerateForecast(ForecastRequest request, CancellationToken cancellationToken);
}
