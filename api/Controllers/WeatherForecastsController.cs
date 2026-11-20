using LabApi.Models;
using LabApi.Services;
using Microsoft.AspNetCore.Mvc;

namespace LabApi.Controllers;

[ApiController]
[Route("api/v1/weather/forecasts")]
public sealed class WeatherForecastsController(IWeatherForecastService forecastService) : ControllerBase
{
    [HttpGet(Name = "GetWeatherForecast")]
    [ProducesResponseType<ForecastResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest)]
    public ActionResult<ForecastResponse> Get([FromQuery] ForecastRequest request, CancellationToken cancellationToken)
    {
        return Ok(forecastService.GenerateForecast(request, cancellationToken));
    }
}
