function Test-DotnetLibrary {
    [CmdletBinding()]
    [Alias('tnl')]
    param(
        # Library to test
        [Parameter(Mandatory)]
        [ArgumentCompleter( {
                param ($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
                $libsSrcPath = Join-Path $global:RuntimeSourcesRoot "src/libraries"
                Get-ChildItem $libsSrcPath -Filter "$wordToComplete*" | ForEach-Object Name
            } )]
        [string] $Name,

        # Library to test
        [Parameter()]
        [ArgumentCompleter( {
                param ($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
                $library = $fakeBoundParameters.Name
                $libsSrcPath = Join-Path $global:RuntimeSourcesRoot "src/libraries/$library/tests"
                Get-ChildItem $libsSrcPath -Filter "$wordToComplete*" | ForEach-Object Name
            } )]
        [string] $TestProject = 'FunctionalTests',

        # Filter for the tests, supports wildcards
        [Parameter()]
        [string] $Filter,

        # Additional arguments to the test process
        [Parameter()]
        [string[]] $AdditionalArguments,

        # Number of iteration to run the test
        [Parameter()]
        [int] $IterationCount = 1,

        # Timeout after which the test run should be aborted and dump should be collected
        [Parameter()]
        [int] $TimeoutSeconds,

        # If set, then iterating will stop when first test failure is encountered
        [Parameter()]
        [switch] $BreakOnTestFailure,

        # If set, then outerloop test category is enabled
        [Parameter()]
        [switch] $Outerloop,

        # Configuration of the library to test
        [Parameter()]
        [ValidateSet("Debug", "Release")]
        [Alias("lc")]
        [string] $LibrariesConfiguration = "Debug",

        # Path to the sources root directory
        [Parameter()]
        [string] $RuntimeSourcesRoot = $global:RuntimeSourcesRoot
    )

    $ErrorActionPreference = 'Stop'

    # First, find the testhost folder, expect that there is exactly one folder with the target configuration
    $testhostDir = Get-ChildItem -Path (Join-Path $RuntimeSourcesRoot "/artifacts/bin/testhost") -Filter "*$LibrariesConfiguration*";
    if ($testhostDir.Length -ne 1) {
        Write-Error "Found more than one testhost:`n$testhostDir"
    }
    $testhostDir = $testhostDir | Select-Object -First 1

    $libraryDir = Join-Path $RuntimeSourcesRoot 'src/libraries' $Name 'tests' $TestProject

    if ($IsWindows) {
        $testhost = Join-Path $testhostDir "dotnet.exe"
    }
    else {
        $testhost = Join-Path $testhostDir "dotnet"
    }

    $arguments = @(
        'test',
        '--no-build',
        '--configuration', $LibrariesConfiguration
    )

    if ($Filter) {
        $arguments += '--filter', $Filter
    }

    if ($AdditionalArguments) {
        $arguments += $AdditionalArguments
    }

    if ($Outerloop) {
        $arguments += "/p:OuterLoop=true"
    }

    Write-Verbose "Working dir: $libraryDir"
    Write-Verbose "Command: dotnet $arguments"

    for ($i = 0; $i -lt $IterationCount; $i++) {
        Write-Verbose "iteration $($i + 1)/$IterationCount"

        $process = Start-Process `
            -FilePath 'dotnet' `
            -WorkingDirectory $libraryDir `
            -ArgumentList $arguments `
            -NoNewWindow `
            -PassThru `

        # wait for the process to finish
        $waitArgs = @{}
        if ($TimeoutSeconds) {
            $waitArgs += @{ Timeout = $TimeoutSeconds }
        }
        $process | Wait-Process @waitArgs -ErrorAction SilentlyContinue

        # If not finished in time, dump the process for analysis
        if (!$process.HasExited) {
            $testPs = Get-Process dotnet | Where-Object { $_.Path -eq $testhost } | Select-Object -First 1
            Write-Verbose "Timeout reached, collecting dump of process $($process.Id)"
            dotnet-dump collect -p $testPs.Id
            $process | Wait-Process

            if ($process.ExitCode -ne 0) {
                break;
            }
        }

        if ($process.ExitCode -ne 0 -and $BreakOnTestFailure) {
            break;
        }
    }
}