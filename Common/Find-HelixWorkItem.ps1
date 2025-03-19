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
        [ValidateSet("Passed", "Failed")]
        [string] $State,

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
    if ($Configuration) {
        $params["Configuration"] = $Configuration
    }

    Get-HelixJob @params -QueueId $QueueId -OperatingSystem $OperatingSystem -PhaseName $PhaseName -DefinitionName $DefinitionName -Count 100 | ForEach-Object {
        $job = $_

        Get-HelixWorkItem -Job $job.Name -Name $Name | Get-HelixWorkItemDetail | ForEach-Object {
            $workItem = $_

            $check = $true

            if ($State) {
                $check = $check -and ($workItem.State -like $State)
            }

            if ($check) {
                [pscustomobject] @{
                    Job             = $job.Name
                    Name            = $workItem.Name
                    DefinitionName  = $job.Properties.DefinitionName
                    Finished        = $workItem.Finished
                    PhaseName       = $job.Properties."System.PhaseName"
                    OperatingSystem = $job.Properties.operatingSystem
                    configuration   = $job.Properties.configuration
                    ConsoleLogUri   = $workItem.ConsoleOutputUri
                    State           = $workItem.State
                }
            }
        }
    }
}