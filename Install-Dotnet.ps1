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
    if ($IsWindows) {
        $installScript = Rename-Item -Path $installScript -NewName ($installScript.BaseName + ".ps1") -PassThru
    }
    else {
        $installScript = Rename-Item -Path $installScript -NewName ($installScript.BaseName + ".sh") -PassThru
    }

    $ProgressPreference = 'SilentlyContinue' # Don't display the console progress UI - it's a huge perf hit
    $dotnetInstallScriptVersion = "v1"

    if ($IsWindows) {
        $uri = "https://dotnet.microsoft.com/download/dotnet/scripts/$dotnetInstallScriptVersion/dotnet-install.ps1"
    }
    else {
        $uri = "https://dotnet.microsoft.com/download/dotnet/scripts/$dotnetInstallScriptVersion/dotnet-install.sh"
    }

    Invoke-WebRequest $uri -OutFile $installScript

    $parameters = @(
        "-Version", $Version
        "-InstallDir", $InstallDir
    )

    if ($DryRun) {
        $parameters += @(
            "-DryRun"
        )
    }

    if ($IsWindows) {
        pwsh $installScript @parameters
    }
    else {
        bash $installScript @parameters
    }

    Remove-Item $installScript
}