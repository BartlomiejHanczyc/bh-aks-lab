FROM mcr.microsoft.com/dotnet/aspnet:10.0

WORKDIR /app

COPY bin/release/net10.0/publish/ .

ENV ASPNETCORE_HTTP_PORTS=8080

EXPOSE 8080

ENTRYPOINT ["dotnet", "LabApi.dll"]