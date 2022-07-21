function Invoke-Perfview {
    [CmdletBinding()]
    param(
        # Start collecting
        [Parameter(ParameterSetName = "Start")]
        [switch] $Start,

        # Stop collecting
        [Parameter(ParameterSetName = "Stop")]
        [switch] $Stop,

        # abort collecting
        [Parameter(ParameterSetName = "Abort")]
        [switch] $Abort,

        # Size of the buffer for collecting data
        [Parameter(ParameterSetName = "Start")]
        [ValidateRange(0, [int32]::MaxValue)]
        [int] $BufferSizeMB,

        # Size of the circular buffer for collecting data
        [Parameter(ParameterSetName = "Start")]
        [ValidateRange(0, [int32]::MaxValue)]
        [int] $CircularMB,

        # .NET Runtime events to collect
        [Parameter(ParameterSetName = "Start")]
        [ValidateSet("JITSymbols", "None")]
        [string[]] $ClrEvents,

        # .NET Threadpool events to collect
        [Parameter(ParameterSetName = "Start")]
        [ValidateSet("None")]
        [string[]] $TplEvents,

        # EventSource providers to collect
        [Parameter(ParameterSetName = "Start")]
        [ValidateSet("Microsoft-Diagnostics-DiagnosticSource")]
        [string[]] $Providers
    )

    $perfview = Get-Command perfview -ErrorAction SilentlyContinue

    if (!$perfview) {
        Write-Error "Cannot find PerfView in Path"
        return
    }

    function RunPerfview($arguments) {
        Write-Verbose "Running ``Perfview $arguments``"

        $info = [System.Diagnostics.ProcessStartInfo]::new()
        $info.FileName = $perfview.Path
        $arguments | ForEach-Object { $info.ArgumentList.Add($_) }
        $info.WorkingDirectory = $PWD.Path
        $info.RedirectStandardInput = $true
        $info.RedirectStandardOutput = $true
        $info.UseShellExecute = $false

        $proc = [System.Diagnostics.Process]::new()
        $proc.StartInfo = $info
        $proc.EnableRaisingEvents = $true

        $output = ""

        $job = Register-ObjectEvent -InputObject $proc -EventName "OutputDataReceived" -Action {
            param($proc, $data)
            Write-Verbose "In callback"


            if ($data) {
                if ($data.Data -contains "Press enter to close window") {
                    # Send writeline to close the process
                    $proc.StandardInput.WriteLine()
                }

                $output += $data.Data
            }
        }

        $null = $proc.Start()
        $proc.BeginOutputReadLine();
        $null = $proc.WaitForExit()
        Receive-Job $job
        $proc.Close()

        if ($output -contains "FAIL") {
            Write-Error $output
        }
    }

    $perfviewArgs = @(
        "/AcceptEula", "/NoGui"
    )

    if ($BufferSizeMB) {
        $perfviewArgs += "/BufferSizeMB=$BufferSizeMB"
    }

    if ($CircularMB) {
        $perfviewArgs += "/CircularMB=$CircularMB"
    }

    if ($ClrEvents) {
        $perfviewArgs += "/ClrEvents=$($ClrEvents -join ',')"
    }

    if ($TplEvents) {
        $perfviewArgs += "/TplEvents=$($TplEvents -join ',')"
    }

    if ($Providers) {
        $perfviewArgs += "/Providers=$($Providers -join ',')"
    }


    switch ($PSCmdlet.ParameterSetName) {
        "Start" {
            RunPerfview (@("start") + $perfviewArgs)
        }
        "Stop" {
            RunPerfview (@("stop") + $perfviewArgs)
        }
        "Abort" {
            RunPerfview (@("abort") + $perfviewArgs)
        }
        default {
            Write-Error "Unknown parameter set"
        }
    }

    # VERBOSE LOG IN: PerfViewData.log.txt
    # Use /LogFile:FILE  to redirect output entirely.
    # EXECUTING: PerfView /RestartingToElevelate: /BufferSizeMB:256 /StackCompression /NoGui /NoNGenRundown Start
    # Kernel Log: C:\Users\radekzikmund\PerfViewData.kernel.etl
    # User mode Log: C:\Users\radekzikmund\PerfViewData.etl
    # DONE 12:37:54 SUCCESS: PerfView /RestartingToElevelate: /BufferSizeMB:256 /StackCompression /NoGui /NoNGenRundown Start
    # Press enter to close window.
}