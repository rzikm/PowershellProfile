Add-Type -TypeDefinition @"
public enum DotnetTraceFormat
{
    Chromium,
    NetTrace,
    Speedscope
}
"@

Add-Type -TypeDefinition @"
public enum ClrEvent
{
    GC,
    GCHandle,
    Fusion,
    Loader,
    JIT,
    NGEN,
    StartEnumeration,
    EndEnumeration,
    Security,
    AppDomainResourceManagement,
    JITTracing,
    Interop,
    Contention,
    Exception,
    Threading,
    JittedMethodILToNativeMap,
    OverrideAndSuppressNGENEvents,
    Type,
    GCHeapDump,
    GCSampledObjectAllcationHigh, // BUG: allcation instead of allocation
    GCHeapSurvivalAndMovement,
    GCHeapCollect,
    GCHeapAndTypeNames,
    GCSampledObjectAllcationLow, // BUG: allcation instead of allocation
    PerfTrack,
    Stack,
    ThreadTransfer,
    Debugger,
}
"@

function Trace-Dotnet
{
    [CmdletBinding()]
    param(
        # Path to the dotnet executable
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $FilePath,

        # Arguments to the executable
        [Parameter(Mandatory = $true, Position = 1)]
        [string[]] $ArgumentList,

        # output trace path
        [Parameter()]
        [string] $OutputTracePath,

        # CLR keywords to collect
        [Parameter(Mandatory = $true)]
        [ClrEvent[]] $ClrEvents,

        # working directory for the process
        [Parameter()]
        [string] $WorkingDirectory = $pwd,

        # Format of the output of the trace
        [Parameter()]
        [DotnetTraceFormat] $OutputFormat = "speedscope"
    )

    # fail fast
    $ErrorActionPreference = 'Stop'

    $executable = Get-ChildItem $filePath

    $clrEventsString = [string]::Join('+', $ClrEvents)

    # Enable tracing config inside CoreCLR
    $Env:COMPlus_PerfMapEnabled=1
    $Env:COMPlus_EnableEventLog=1

    $dotnetPs = Start-Process `
      -FilePath dotnet `
      -ArgumentList ((,$executable) + $argumentList) `
      -WorkingDirectory $workingDirectory `
      -RedirectStandardOutput /dev/null `
      -NoNewWindow `
      -PassThru

    $clrEventsString = $clrEventsString.ToLower()

    dotnet-trace collect --process-id $dotnetPs.Id --clrevents $clrEventsString --format $OutputFormat `
      --providers Microsoft-Windows-DotNETRuntime:0x200000:1

    Stop-Process $dotnetPs
}
