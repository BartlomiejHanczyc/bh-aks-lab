using System.ComponentModel.DataAnnotations;

namespace LabApi.Configuration;

public sealed class SimulationOptions
{
    public const string SectionName = "Simulation";

    [Range(1, 60)]
    public int TimeStepMinutes { get; init; } = 10;
}
