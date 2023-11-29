function Find-HelixWorkItem {
    [CmdletBinding()]
    [Alias('fhwi')]
    param(
        [Parameter(ParameterSetName = "BuildId")]
        [string] $BuildId,

        [Parameter(ParameterSetName = "PullRequest")]
        [string] $PullRequestId,

        [Parameter()]
        [string] $Name,

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
        [string] $Configuration
    )

    $params = @{}
    if ($BuildId) {
        $params["BuildId"] = $BuildId
    }
    if ($PullRequestId) {
        $params["PullRequestId"] = $PullRequestId
    }

    Get-HelixJob @params -Count 100 | Where-Object {
        $res = $true

        if ($QueueId) {
            $res = $res -and $_.QueueId -like "*$QueueId*"
        }
        if ($PhaseName) {
            $res = $res -and $_.Properties."System.PhaseName" -like "*$PhaseName*"
        }
        if ($DefinitionName) {
            $res = $res -and $_.Definition.Name -like "*$DefinitionName*"
        }
        if ($OperatingSystem) {
            $res = $res -and $_.Properties.operatingSystem -like "*$OperatingSystem*"
        }
        if ($Configuration) {
            $res = $res -and $_.Properties.configuration -eq $Configuration
        }

        $res
    } | ForEach-Object {
        $job = $_

        Get-HelixWorkItem -Job $job.Name -Name $Name | Get-HelixWorkItemDetail | ForEach-Object {
            $workItem = $_

            [pscustomobject] @{
                Job = $job.Name
                Name = $workItem.Name
                DefinitionName = $job.Definition.Name
                Finished = $workItem.Finished
                PhaseName = $job.Properties."System.PhaseName"
                OperatingSystem = $job.Properties.operatingSystem
                configuration = $job.Properties.configuration
                ConsoleLogUri = $workItem.ConsoleOutputUri
            }
        }
    }
}