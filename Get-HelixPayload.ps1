function Get-HelixPayload {
    [CmdletBinding()]
    [Alias('ghp')]
    param(
        # Helix job id
        [Parameter(Mandatory)]
        [string] $JobId,

        # Work item id
        [Parameter(Mandatory)]
        [string] $WorkItemId,

        # Path where the payload should be extracted
        [Parameter(Mandatory)]
        [string] $OutDir
    )

    # download payload
    runfo get-helix-payload -j $JobId -w $WorkItemId -o $OutDir

    # extract all zips files
    $zips = Get-ChildItem -Recurse -LiteralPath $OutDir -Filter *.zip
    $zips | Expand-Archive -DestinationPath $OutDir
    Remove-Item $zips
}