function Test-DotnetLibrary {
    [CmdletBinding()]
    [Alias('tnl')]
    param(
        # Library to test
        [Parameter(Mandatory)]
        [ArgumentCompleter( {
                param ($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
                $libsSrcPath = Join-Path $global:RuntimeSourcesRoot "artifacts/bin"
                Get-ChildItem $libsSrcPath -Filter "$wordToComplete*" | Where-Object { $_.Name -like "*Tests" } | ForEach-Object Name
            } )]
        [string] $Name,

        # Number of iteration to run the test
        [Parameter()]
        [int] $IterationCount = 1,

        # Timeout after which the test run should be aborted and dump should be collected
        [Parameter()]
        [int] $TimeoutSeconds,

        # Additional arguments to the test process
        [Parameter()]
        [string[]] $AdditionalArguments,

        # Configuration of the library to test
        [Parameter()]
        [ValidateSet("Debug", "Release")]
        [Alias("lc")]
        [string] $LibrariesConfiguration = "Debug",

        # Filter for the tests
        [Parameter()]
        [string] $TestFilter,

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

    # Now find the library folder
    $libraryDir = Get-ChildItem -Path (Join-Path $RuntimeSourcesRoot "/artifacts/bin/" $Name $LibrariesConfiguration)
    if ($testhostDir.Length -ne 1) {
        Write-Error "Found more than one library bin dir:`n$libraryDir"
    }

    if ($IsWindows) {
        $testhost = Join-Path $testhostDir "dotnet.exe"
    }
    else {
        $testhost = Join-Path $testhostDir "dotnet"
    }

    # /root/helix/work/correlation/dotnet exec --runtimeconfig System.Net.Security.Tests.runtimeconfig.json --depsfile System.Net.Security.Tests.deps.json xunit.console.dll System.Net.Security.Tests.dll -xml testResults.xml -nologo -nocolor -notrait category=IgnoreForCI 

    $arguments = @(
        'exec',
        '--runtimeconfig', "$Name.runtimeconfig.json",
        '--depsfile', "$Name.deps.json",
        'xunit.console.dll',
        "$Name.dll"
    )

    if ($TestFilter) {
        $arguments += '-method', "*$TestFilter*"
    }

    if ($AdditionalArguments) {
        $arguments += $AdditionalArguments
    }

    Write-Verbose "$testhost $arguments"

    for ($i = 0; $i -lt $IterationCount; $i++) {
        # Start the dotnet exec process
        $process = Start-Process `
            -FilePath $testhost `
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
            dotnet-dump collect -p $process.Id
        }
    }
}