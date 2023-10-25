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
        [string] $OutDir,

        # Whether to download DAC binaries
        [Parameter()]
        [switch] $DownloadDacBinaries
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

    if ($DownloadDacBinaries)
    {
        $buildid = Select-String -Path "$OutDir/scripts/*/execute.sh" "buildid (\d+)" | Select-Object -First 1 | Foreach-Object { $_.Matches.Groups[1].Value }
        Invoke-WebRequest "https://dev.azure.com/dnceng-public/public/_apis/build/builds/$buildid/artifacts?artifactName=CoreCLRCrossDacArtifacts&api-version=6.0&%24format=zip" -OutFile "$OutDir/CoreClrCrossDacArtifacts.zip"
        Expand-Archive "$OutDir/CoreClrCrossDacArtifacts.zip" -DestinationPath "$OutDir"
        Remove-Item "$OutDir/CoreClrCrossDacArtifacts.zip"
    }
}