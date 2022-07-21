function Get-HelixPayload {
    [CmdletBinding()]
    [Alias('ghp')]
    param(
        # Helix job id
        [Parameter(Mandatory, ParameterSetName = "JobAndWorkItem")]
        [string] $JobId,

        # Work item id
        [Parameter(Mandatory, ParameterSetName = "JobAndWorkItem")]
        [string] $WorkItemId,

        # Link to the console output
        [Parameter(Mandatory, ParameterSetName = "ConsoleUri")]
        [string] $ConsoleUri,

        # Path where the payload should be extracted
        [Parameter(Mandatory)]
        [string] $OutDir
    )

    if ($PSCmdlet.ParameterSetName -eq "ConsoleUri") {
        $content = Invoke-RestMethod -Uri $ConsoleUri
        if ($content -match "Console log: '([^']+)' from job ([^ ]+) ") {
            $WorkItemId = $Matches[1]
            $JobId = $Matches[2]
        }
        else {
            Write-Error "Unable to retrieve WorkItemId and JobId from the console log"
        }
    }

    # download payload
    runfo get-helix-payload -j $JobId -w $WorkItemId -o $OutDir

    # extract all zips files
    $zips = Get-ChildItem -Recurse -LiteralPath $OutDir -Filter *.zip
    $zips | Expand-Archive -DestinationPath $OutDir
    Remove-Item $zips
}