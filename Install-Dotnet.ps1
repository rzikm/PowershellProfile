function Install-Dotnet {
    param(
        [Parameter(ParameterSetName = "Version")]
        [string] $Version,

        [Parameter(ParameterSetName = "Channel")]
        [ValidateSet("Current", "LTS", "6.0", "7.0", "8.0", "9.0", "10.0")]
        [string] $Channel,

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

    $parameters = @()

    if ($PSBoundParameters['Verbose']) {
        $parameters += "-Verbose"
    }

    switch ($PSCmdlet.ParameterSetName) {
        "Version" {
            $parameters += "-Version", $Version
        }
        "Channel" {
            $parameters += "-Channel", $Channel
        }
    }

    if ($InstallDir) {
        $parameters += "-InstallDir", $InstallDir
    }

    if ($DryRun) {
        $parameters += "-DryRun"
    }

    if ($IsWindows) {
        pwsh $installScript @parameters
    }
    else {
        bash $installScript @parameters
    }

    Remove-Item $installScript
}
