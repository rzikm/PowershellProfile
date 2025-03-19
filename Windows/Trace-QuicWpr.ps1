function Trace-QuicWpr {
    [CmdLetBinding()]
    param (
        [Parameter()]
        [string] $FilePath = "msquic.etl",

        [Parameter()]
        [ValidateSet(
            'Stacks.Light', #Collects CPU callstacks
            'Stacks.Verbose', # Collects CPU callstacks, DPCs and interrupts.
            'Performance.Light', # Collects performance related events useful for automated tool processing.
            'Performance.Verbose', # Collects `Performance.Light` plus CPU callstacks.
            'Basic.Light', # Collects general, "low volume" MsQuic events. Useful for a "big picture" understanding, with as few events collected as possible.
            'Basic.Verbose', # Collects all MsQuic events. This is very verbose.
            'Scheduling.Verbose', # Collects "low volume" and scheduling related MsQuic events.
            'Datapath.Light', # Collects "low volume" and datapath related MsQuic events.
            'Datapath.Verbose', # Collects `Datapath.Light` plus CPU callstacks.
            'Full.Light', # Collects all MsQuic events as well as [TAEF](https://docs.microsoft.com/en-us/windows-hardware/drivers/taef/) events. For most, this will be equivalent to `Basic.Verbose`.
            'Full.Verbose' # Collects all MsQuic events, [TAEF](https://docs.microsoft.com/en-us/windows-hardware/drivers/taef/) events and several networking components' events. This is the **most verbose** possible, and should only be used for the most minimal scenarios.
        )]
        [Alias('Profile')]
        [string] $ProfileName,

        [Parameter()]
        [ScriptBlock] $ScriptBlock
    )

    if (!$ScriptBlock) {
        $ScriptBlock = {
            Write-Host "Press enter to stop trace collection..."
            Read-Host
        }
    }

    $wprpPath = Join-Path $global:MsQuicRoot "src/manifest/MsQuic.wprp"

    sudo.exe wpr.exe -start "$wprpPath!$ProfileName" -filemode

    & $ScriptBlock

    sudo.exe wpr.exe -stop $FilePath
}