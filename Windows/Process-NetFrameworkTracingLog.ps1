function Process-NetFrameworkTracingLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogPath,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "$($LogPath).formatted.log"
    )

    
    # Check if input file exists
    if (-not (Test-Path $logPath)) {
        Write-Error "Input log file not found: $logPath"
        exit 1
    }
    
    # Read all lines from the file
    $lines = Get-Content $logPath
    $outputLines = @()
    
    $logLine = ""
    $processId = ""
    $dateTimeStr = ""
    
    foreach ($line in $lines) {
        if ($line -match '^(System[^[]*\[\d+\]) ') {
            $header = $Matches[1]
            if ($logLine -ne "" -and $processId -ne "" -and $dateTimeStr -ne "") {
                # Format the dateTime to get just the time portion (HH:MM:SS.fffffff)
                if ($dateTimeStr -match '\d{4}-\d{2}-\d{2}T(\d{2}:\d{2}:\d{2}\.\d+)') {
                    $timeStr = $matches[1]
                    # Format the output line
                    $formattedLine = "[$processId][$timeStr] - $logLine"
                    $outputLines += $formattedLine

                    foreach ($logLine in $logLines) {
                        $outputLines += "[$processId][$timeStr] - $header $logLine"
                    }
                }
                else {
                    Write-Warning "Error processing line starting with '$line'. DateTime format not recognized."
                    # In case DateTime doesn't match expected format, keep original lines
                    $outputLines += $logLine
                    $outputLines += "ProcessId=$processId"
                    $outputLines += "DateTime=$dateTimeStr"
                }
            }
            # Reset for new block
            $logLine = $line
            $logLines = @()
            $processId = ""
            $dateTimeStr = ""
        }
        elseif ($line -match '\s*ProcessId=(\d+)') {
            $processId = $matches[1]
        }
        elseif ($line -match '\s*DateTime=(.+)Z') {
            $dateTimeStr = $matches[1]
        }
        else {
            $logLines += @($line)
        }
    }
    
    # Process the last block if any
    if ($logLine -ne "" -and $processId -ne "" -and $dateTimeStr -ne "") {
        if ($dateTimeStr -match '\d{4}-\d{2}-\d{2}T(\d{2}:\d{2}:\d{2}\.\d+)') {
            $timeStr = $matches[1]
            $formattedLine = "[$processId][$timeStr] - $logLine"
            $outputLines += $formattedLine
        }
        else {
            $outputLines += $logLine
            $outputLines += "ProcessId=$processId"
            $outputLines += "DateTime=$dateTimeStr"
        }
    }
    
    # Write output to file
    $outputLines | Out-File -FilePath $outputPath -Encoding utf8
    
    Write-Host "Log processing completed. Output saved to: $outputPath"
    Write-Host "Processed $($lines.Count) input lines into $($outputLines.Count) output lines"
}