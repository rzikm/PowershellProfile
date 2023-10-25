function Run-DotnetBenchmark
{
    [CmdletBinding()]
    param(
        # Git branches of the repository which should participate in the benchmark, defaults to current branch
        [Parameter()]
        [ArgumentCompleter({
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
            $root = $fakeBoundParameters.RuntimeSourcesRoot ?? $global:RuntimeSourcesRoot
            git -C $root for-each-ref --format='%(refname:short)' refs/heads/ |
                Where-Object { $_ -like "$wordToComplete*" }
        })]
        [string[]] $GitBranch,

        [Parameter()]
        [ValidateSet("6.0", "7.0", "8.0", "9.0")]
        [string] $Framework = "9.0",

        # Filter on the benchmarks to run
        [Parameter()]
        [string] $BenchmarkFilter,

        # Path where to store results
        [Parameter()]
        [string] $ArtifactsPath,

        # If true, runtime is rebuilt (with -s Libs+Libs.Test -c Release)
        [Parameter()]
        [switch] $BuildRuntime,

        # Projects to explicitly rebuild after switching branches, can speedup when comparing two branches
        [Parameter()]
        [ArgumentCompleter({
            param ($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
            $root = $fakeBoundParameters.RuntimeSourcesRoot ?? $global:RuntimeSourcesRoot
            Get-ChildItem $root/src/libraries -Filter "$wordToComplete*" | ForEach-Object Name
        })]
        [string[]] $ProjectsToRebuild,

        # Path to the dotnet/runtime repo
        [Parameter()]
        [string] $RuntimeSourcesRoot = $global:RuntimeSourcesRoot,

        # Path to the dotnet/performance repo
        [Parameter()]
        [string] $PerformanceSourcesRoot = $global:DotnetPerformanceSourcesRoot
    )

    # Stop on errors
    $ErrorActionPreference = "Stop"

    if ($BuildRuntime)
    {
        Build-DotnetRuntime -Subset Libs, Libs.Tests -LibrariesConfiguration Release -RuntimeSourcesRoot $RuntimeSourcesRoot -RuntimeConfiguration Release
    }

    if (!$GitBranch)
    {
        # Get current branch name
        $GitBranch = git -C $RuntimeSourcesRoot rev-parse --abbrev-ref HEAD
    }

    if ($IsWindows)
    {
        $testHostRoot = "$RuntimeSourcesRoot/artifacts/bin/testhost/net$Framework-windows-Release-x64/shared/Microsoft.NETCore.App"
    }
    if ($IsLinux)
    {
        $testHostRoot = "$RuntimeSourcesRoot/artifacts/bin/testhost/net$Framework-Linux-Release-x64/shared/Microsoft.NETCore.App"
    }

    $coreruns = @()

    foreach ($branch in $GitBranch)
    {
        if ($ProjectsToRebuild)
        {
            git -C $RuntimeSourcesRoot checkout $branch

            # Rebuild changed projects
            foreach ($proj in $ProjectsToRebuild)
            {
                dotnet build $RuntimeSourcesRoot/src/libraries/$proj/src/$proj.csproj --no-restore --configuration Release
            }

            # save the testhost
            if (Test-Path $testHostRoot/$branch)
            {
                Remove-Item -Recurse -Force $testHostRoot/$branch
            }
            Copy-Item -Recurse "$testHostRoot/$Framework.0" $testHostRoot/$branch
        }

        if ($IsWindows)
        {
            $coreruns += "$testHostRoot/$branch/corerun.exe"
        }
        else
        {
            $coreruns += "$testHostRoot/$branch/corerun"
        }
    }

    # compose command line args
    $benchmarkArgs = @("-f", "net8.0")

    if ($BenchmarkFilter)
    {
        $benchmarkArgs += "--filter", "*$BenchmarkFilter*"
    }

    $benchmarkArgs += "--corerun"
    $benchmarkArgs += $coreruns

    python3 $PerformanceSourcesRoot/scripts/benchmarks_ci.py @benchmarkArgs
}