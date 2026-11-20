using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.ModelBinding;

namespace LabApi.Models;

public sealed class ForecastRequest
{
    public const int MaxDays = 14;
    public const int MaxEnsembleMembers = 50_000;

    [FromQuery(Name = "latitude")]
    [BindRequired]
    [Range(-90.0, 90.0)]
    public double Latitude { get; init; }

    [FromQuery(Name = "longitude")]
    [BindRequired]
    [Range(-180.0, 180.0)]
    public double Longitude { get; init; }

    [FromQuery(Name = "days")]
    [Range(1, MaxDays)]
    public int Days { get; init; } = 7;

    [FromQuery(Name = "ensembleMembers")]
    [Range(1, MaxEnsembleMembers)]
    public int EnsembleMembers { get; init; } = 10_000;
}
