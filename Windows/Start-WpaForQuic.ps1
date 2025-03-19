function Start-WpaForQuic {
    [CmdLetBinding()]
    param (
        [Parameter()]
        [string] $FilePath
    )
    $scriptPath = Join-Path $global:MsQuicRoot "scripts/wpa.ps1"
    &$scriptPath -FilePath (Get-Item $FilePath)
}