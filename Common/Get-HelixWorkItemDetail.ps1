function Get-HelixWorkItemDetail {
    [CmdletBinding()]
    [Alias('ghwid')]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string] $Job,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string] $Name
    )

    process
    {
        Invoke-HelixApi -Path "jobs/$Job/workitems/$Name"
    }
}