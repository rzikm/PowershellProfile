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

        # Run xUnit directly instead of using dotnet test
        [Parameter(ParameterSetName = "Direct")]
        [switch] $Direct,

        # Override for framework version
        [Parameter(ParameterSetName = "Direct")]
        [ValidateSet('*', '8.0', '9.0', '10.0')]
        [string] $Framework = '*', # use the only one by default

        # Filter for the tests, supports wildcards
        [Parameter()]
        [string] $Filter,

        # Additional arguments to the test process
        [Parameter()]
        [string[]] $AdditionalArguments,

        # Max threadpool threads
        [Parameter()]
        [int] $MaxThreads,

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
    $testhostDir = Get-ChildItem -Path (Join-Path $RuntimeSourcesRoot "/artifacts/bin/testhost") -Filter "*$Framework*$LibrariesConfiguration*";
    if ($testhostDir.Length -ne 1) {
        Write-Error "Found more than one testhost:`n$testhostDir"
    }
    $testhostDir = $testhostDir | Select-Object -First 1

    if ($IsWindows) {
        $testhost = Join-Path $testhostDir "dotnet.exe"
    }
    else {
        $testhost = Join-Path $testhostDir "dotnet"
    }

    $projectPath = Join-Path $RuntimeSourcesRoot 'src/libraries' $Name 'tests' $TestProject

    if ($Direct) {
        $projectName = Get-ChildItem -Path $projectPath -Filter '*.csproj' | Select-Object -First 1 -ExpandProperty BaseName

        $program = $testhost

        $artifactDir = Join-Path $RuntimeSourcesRoot 'artifacts/bin' $projectName $LibrariesConfiguration

        if ($IsWindows) {
            $target = Get-ChildItem -Path $artifactDir -Filter "net$Framework-windows" | Select-Object -Last 1 -ExpandProperty BaseName
        }
        if ($IsLinux) {
            $target = Get-ChildItem -Path $artifactDir -Filter "net$Framework-linux" | Select-Object -Last 1 -ExpandProperty BaseName
        }
        if ($IsMacOs) {
            $target = Get-ChildItem -Path $artifactDir -Filter "net$Framework-osx" | Select-Object -Last 1 -ExpandProperty BaseName
        }

        if (!($target) -and ($IsLinux -or $IsMacOs)) {
            $target = Get-ChildItem -Path $artifactDir -Filter "net$Framework-unix" | Select-Object -Last 1 -ExpandProperty BaseName
        }

        if (!($target)) {
            Write-Error "Unable to find testhost for $Framework in $artifactDir"
            return
        }

        $workDir = Join-Path $artifactDir $target

        $arguments = @(
            'exec',
            '--runtimeconfig', "$ProjectName.runtimeconfig.json",
            '--depsfile', "$ProjectName.deps.json",
            '/home/rzikm/.nuget/packages/microsoft.dotnet.xunitconsolerunner/2.9.2-beta.25058.4/build/../tools/net/xunit.console.dll'
            "$ProjectName.dll"
            '-notrait', 'Category=Failing'
        )

        if ($Filter) {
            $arguments += '-method', "*$Filter*"
        }

        if ($Outerloop) {
            $arguments += '-trait', 'Category=OuterLoop'
        }
        else {
            $arguments += '-notrait', 'Category=OuterLoop'
        }

        if ($BreakOnTestFailure) {
            $arguments += '-stoponfail'
        }

        if ($MaxThreads) {
            $arguments += '-maxthreads', $MaxThreads
        }
    }
    else {
        $program = 'dotnet'
        $workDir = $projectPath

        $arguments = @(
            'test',
            '--no-build',
            '--configuration', $LibrariesConfiguration
        )

        if ($Filter) {
            $arguments += '--filter', "$Filter"
        }

        if ($Outerloop) {
            $arguments += "/p:OuterLoop=true"
        }
    }

    if ($AdditionalArguments) {
        $arguments += $AdditionalArguments
    }

    Write-Verbose "Working dir: $workDir"
    Write-Verbose "Command: $program $arguments"

    $env = @{
        XUNIT_HIDE_PASSING_OUTPUT_DIAGNOSTICS = "1"
    }

    for ($i = 0; $i -lt $IterationCount; $i++) {
        Write-Verbose "iteration $($i + 1)/$IterationCount"

        $process = Start-Process `
            -FilePath $program `
            -WorkingDirectory $workDir `
            -ArgumentList $arguments `
            -NoNewWindow `
            -Environment $env `
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
