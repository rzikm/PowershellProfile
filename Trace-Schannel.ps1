function Trace-Schannel {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string] $DirPath,

        [Parameter()]
        [ScriptBlock] $ScriptBlock
    )

    if ($ScriptBlock -eq $null) {
        $ScriptBlock = {
            Write-Host "Press enter to stop trace collection..."
            Read-Host
        }
    }

    if ($DirPath -eq $null) {
        $DirPath = $pwd
    }

    logman start schannel_trace -p "{37D2C3CD-C5D4-4587-8531-4696C44244C8}" 0x7fffffff -o (Join-Path $DirPath schannel.etl) -ets -ln schannel
    logman start ncryptsslp_trace -p "{A74EFE00-14BE-4ef9-9DA9-1484D5473304}” 0x7fffffff -o (Join-Path $DirPath ncryptsslp.etl) -ets -ln ncryptsslp

    & $ScriptBlock

    logman stop schannel_trace -ets
    logman stop ncryptsslp_trace -ets

}