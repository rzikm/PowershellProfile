function Get-HelixPayload {
    [CmdletBinding(DefaultParameterSetName = "ConsoleUri")]
    [Alias('ghp')]
    param(
        # Helix job id
        [Parameter(Mandatory, ParameterSetName = "JobAndWorkItem")]
        [string] $Job,

        # Work item id
        [Parameter(Mandatory, ParameterSetName = "JobAndWorkItem")]
        [string] $WorkItem,

        # Link to the console output
        [Parameter(Mandatory, ParameterSetName = "ConsoleUri")]
        [string] $ConsoleUri,

        # Path where the payload should be extracted
        [Parameter(Mandatory)]
        [string] $OutDir,

        # Whether to download DAC binaries
        [Parameter()]
        [switch] $DownloadDacBinaries,

        # Don't unzip the downloaded archives
        [Parameter()]
        [switch] $NoUnzip
    )

    if ($PSCmdlet.ParameterSetName -eq "ConsoleUri") {
        $content = Invoke-RestMethod -Uri $ConsoleUri
        if ($content -match "Console log: '([^']+)' from job ([^ ]+) ") {
            $WorkItem = $Matches[1]
            $Job = $Matches[2]
        }
        else {
            Write-Error "Unable to retrieve WorkItemId and JobId from the console log"
        }
    }

    # download payload
    runfo get-helix-payload -j $Job -w $WorkItem -o $OutDir

    # extract all zips files
    if (!$NoUnzip) {
        $zips = Get-ChildItem -Recurse -LiteralPath $OutDir -Filter *.zip
        $zips | Expand-Archive -DestinationPath $OutDir
        Remove-Item $zips
    }

    if ($DownloadDacBinaries) {
        $buildid = Select-String -Path "$OutDir/scripts/*/execute.sh" "buildid (\d+)" | Select-Object -First 1 | Foreach-Object { $_.Matches.Groups[1].Value }
        Invoke-WebRequest "https://dev.azure.com/dnceng-public/public/_apis/build/builds/$buildid/artifacts?artifactName=CoreCLRCrossDacArtifacts&api-version=6.0&%24format=zip" -OutFile "$OutDir/CoreClrCrossDacArtifacts.zip"
        Expand-Archive "$OutDir/CoreClrCrossDacArtifacts.zip" -DestinationPath "$OutDir"
        Remove-Item "$OutDir/CoreClrCrossDacArtifacts.zip"
    }
}