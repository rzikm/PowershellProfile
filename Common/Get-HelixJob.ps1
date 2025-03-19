function Get-HelixJob {
    [CmdletBinding()]
    [Alias('ghj')]
    param(
        [Parameter(ParameterSetName = "BuildId")]
        [string] $BuildId,

        [Parameter(ParameterSetName = "PullRequest")]
        [string] $PullRequestId,

        [Parameter()]
        [string] $QueueId,

        [Parameter()]
        [string] $OperatingSystem,

        [Parameter()]
        [string] $PhaseName,

        [Parameter()]
        [string] $DefinitionName,

        [Parameter()]
        [ValidateSet("Debug", "Release")]
        [string] $Configuration,

        [Parameter()]
        [int] $Count = 20
    )

    $urlParameters = @{}

    if ($BuildId) {
        $urlParameters["buildId"] = $BuildId
    }

    if ($PullRequestId) {
        $urlParameters["source"] = "pr/public/dotnet/runtime/refs/pull/$PullRequestId/merge"
    }

    $urlParameters["count"] = $Count

    Invoke-HelixApi -Path "jobs" -UrlParameters $urlParameters | Where-Object {
        $res = $true

        if ($QueueId) {
            $res = $res -and $_.QueueId -like "*$QueueId*"
        }
        if ($PhaseName) {
            $res = $res -and $_.Properties."System.PhaseName" -like "*$PhaseName*"
        }
        if ($DefinitionName) {
            $res = $res -and $_.Properties.DefinitionName -like "*$DefinitionName*"
        }
        if ($OperatingSystem) {
            $res = $res -and $_.Properties.operatingSystem -like "*$OperatingSystem*"
        }
        if ($Configuration) {
            $res = $res -and $_.Properties.configuration -eq $Configuration
        }

        $res
    }
}