namespace LabApi.Models;

public sealed record TemperatureSummary(
    double Minimum,
    double Maximum,
    double Mean,
    double Percentile10,
    double Percentile90);
