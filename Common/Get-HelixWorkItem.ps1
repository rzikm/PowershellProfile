function Get-HelixWorkItem {
    [CmdletBinding()]
    [Alias('ghwi')]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string] $Job,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $Name
    )

    Invoke-HelixApi -Path "jobs/$Job/workitems" | Where-Object {
        if ($Name) {
            $_.Name -like "*$Name*"
        }
        else {
            $true
        }
    }
}