function Run-DotnetTesthost {
    [Alias('dotnet-testhost')]
    param()

    $dotnet = Get-ChildItem $global:RuntimeSourcesRoot\artifacts\bin\testhost\**\dotnet* | Select-Object -First 1

    & $dotnet $args
}