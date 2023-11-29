function Get-HelixJob {
    [CmdletBinding()]
    [Alias('ghj')]
    param(
        [Parameter(ParameterSetName = "BuildId")]
        [string] $BuildId,

        [Parameter(ParameterSetName = "PullRequest")]
        [string] $PullRequestId,

        [Parameter()]
        [int] $Count = 20,

        [Parameter()]
        [string] $PhaseName
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
        if ($PhaseName) {
            $_.Properties."System.PhaseName" -like "*$PhaseName*"
        }
        else {
            $true
        }
    }
}