function Install-Dotnet {
    param(
        [Parameter()]
        [string] $Version,

        [Parameter()]
        [string] $InstallDir,

        [Parameter()]
        [switch] $DryRun
    )

    $installScript = New-TemporaryFile
    $installScript = Rename-Item -Path $installScript -NewName ($installScript.BaseName + ".ps1") -PassThru

    $ProgressPreference = 'SilentlyContinue' # Don't display the console progress UI - it's a huge perf hit
    $dotnetInstallScriptVersion = "v1"
    $uri = "https://dotnet.microsoft.com/download/dotnet/scripts/$dotnetInstallScriptVersion/dotnet-install.ps1"

    Invoke-WebRequest $uri -OutFile $installScript

    $parameters = @{
        Version    = $Version
        InstallDir = $InstallDir
    }

    if ($DryRun) {
        $parameters += @{ DryRun = $true }
    }

    & $installScript @parameters

    Remove-Item $installScript
}