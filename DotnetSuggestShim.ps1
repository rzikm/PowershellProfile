# dotnet suggest shell start
if (Get-Command "dotnet-suggest" -errorAction SilentlyContinue) {
    Invoke-Expression (dotnet-suggest script powershell | Out-String)
}