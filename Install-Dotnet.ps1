function Install-Dotnet {
    param(
        [Parameter(ParameterSetName = "Version")]
        [string] $Version,

        [Parameter(ParameterSetName = "Channel")]
        [ValidateSet("Current", "LTS", "6.0", "7.0", "8.0", "9.0", "10.0")]
        [string] $Channel,

        [Parameter()]
        [string] $InstallDir,

        [Parameter(ParameterSetName = "Channel")]
        [ValidateSet("daily", "signed", "validated", "preview", "GA")]
        [string] $Quality,

        [Parameter()]
        [switch] $DryRun
    )

    if (!$IsWindows) {
        $installScript = New-TemporaryFile
        $installScript = Rename-Item -Path $installScript -NewName ($installScript.BaseName + ".sh") -PassThru
    }

    $ProgressPreference = 'SilentlyContinue' # Don't display the console progress UI - it's a huge perf hit
    $dotnetInstallScriptVersion = "v1"

    if ($IsWindows) {
        # $uri = "https://dotnet.microsoft.com/download/dotnet/scripts/$dotnetInstallScriptVersion/dotnet-install.ps1"
        # $script = [scriptblock]::Create((Invoke-WebRequest $uri))
    }
    else {
        $installScript = New-TemporaryFile
        $uri = "https://dotnet.microsoft.com/download/dotnet/scripts/$dotnetInstallScriptVersion/dotnet-install.sh"
        Invoke-WebRequest $uri -OutFile $installScript
    }

    $parameters = @{}

    if ($PSBoundParameters['Verbose']) {
        $parameters.Verbose = $true
    }

    switch ($PSCmdlet.ParameterSetName) {
        "Version" {
            $parameters.Version = $Version
        }
        "Channel" {
            $parameters.Channel = $Channel
        }
    }

    if ($InstallDir) {
        $parameters.InstallDir = $InstallDir
    }

    if ($Quality) {
        $parameters.Quality = $Quality
    }

    if ($DryRun) {
        $parameters.DryRun = $true
    }

    if ($IsWindows) {
        & $Script @parameters
    }
    else {
        $scriptParams = @()
        foreach ($key in $parameters.Keys) {
            $scriptParams += "-$key", $parameters[$key]
        }
        bash $installScript @scriptParams
        Remove-Item $installScript
    }
}
