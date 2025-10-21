function Run-DotnetBenchmark {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ArgumentCompleter({
                param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
                $root = $fakeBoundParameters.RuntimeSourcesRoot ?? $global:RuntimeSourcesRoot
                $framework = $fakeBoundParameters.Framework ?? $global:RuntimeLatestFramework

                if ($IsWindows) {
                    $OS = "windows"
                }
                elseif ($IsLinux) {
                    $OS = "linux"
                }
                elseif ($IsOSX) {
                    $OS = "osx"
                }

                $dir = Join-Path $RuntimeSourcesRoot "artifacts\bin\testhost\net$Framework-$OS-Release-x64\shared\Microsoft.NETCore.App"

                Get-ChildItem -Path $dir -Directory | ForEach-Object { $_.Name }
            })]
        [string[]] $CoreRuns,

        [Parameter()]
        [ValidateSet("8.0", "9.0", "10.0")]
        [string] $Framework = $global:RuntimeLatestFramework,

        # Filter on the benchmarks to run
        [Parameter()]
        [string] $BenchmarkFilter,

        # Minimum iteration count for each benchmark
        [Parameter()]
        [int] $MinIterationCount,

        # Maximum iteration count for each benchmark
        [Parameter()]
        [int] $MaxIterationCount,

        # Iteration time for each benchmark
        [Parameter()]
        [int] $IterationTimeMs,

        # Path where to store results
        [Parameter()]
        [string] $ArtifactsPath,

        # Path to the dotnet/runtime repo
        [Parameter()]
        [string] $RuntimeSourcesRoot = $global:RuntimeSourcesRoot,

        # Path to the dotnet/performance repo
        [Parameter()]
        [string] $PerformanceSourcesRoot = $global:DotnetPerformanceSourcesRoot
    )

    # Stop on errors
    $ErrorActionPreference = "Stop"

    if ($IsWindows) {
        $OS = "windows"
    }
    elseif ($IsLinux) {
        $OS = "linux"
    }
    elseif ($IsOSX) {
        $OS = "osx"
    }

    $dir = Join-Path $RuntimeSourcesRoot "artifacts\bin\testhost\net$Framework-$OS-Release-x64\shared\Microsoft.NETCore.App"

    if ($BenchmarkFilter) {
        $benchmarkArgs += "--filter", "*$BenchmarkFilter*"
    }

    foreach ($name in $CoreRuns) {
        if ($IsWindows) {
            $corerun = Get-Item (Join-Path $dir $name "corerun.exe")
        }
        else {
            $corerun = Get-Item (Join-Path $dir $name "corerun")
        }

        $benchmarkArgs += "--corerun", $corerun.FullName
    }

    if ($ArtifactsPath) {
        if (-not (Test-Path $ArtifactsPath)) {
            New-Item -ItemType Directory -Path $ArtifactsPath | Out-Null
        }
        $benchmarkArgs += "--artifacts", $ArtifactsPath
    }

    if ($MinIterationCount) {
        $benchmarkArgs += "--minIterationCount=$MinIterationCount"
    }

    if ($MaxIterationCount) {
        $benchmarkArgs += "--maxIterationCount=$MaxIterationCount"
    }

    if ($IterationTimeMs) {
        $benchmarkArgs += "--iterationTime=$IterationTimeMs"
    }

    $projectPath = Join-Path $PerformanceSourcesRoot "src/benchmarks/micro/MicroBenchmarks.csproj"

    dotnet run -c Release --project $projectPath --framework "net$Framework" -- $benchmarkArgs
}
