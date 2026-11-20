namespace LabApi.Models;

public sealed record ForecastResponse(
    double Latitude,
    double Longitude,
    DateTimeOffset GeneratedAt,
    int EnsembleMembers,
    int TimeStepMinutes,
    double ComputationMilliseconds,
    IReadOnlyList<DailyForecast> Days);
