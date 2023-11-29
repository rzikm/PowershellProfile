function Invoke-HelixApi {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [string] $BaseUrl = "https://helix.dot.net/api",

        [Parameter()]
        [string] $Path,

        [Parameter()]
        [hashtable] $UrlParameters = @{}
    )

    $uri = $BaseUrl

    if ($Path) {
        $uri += "/" + $Path
    }

    $queryValues = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
    foreach ($key in $UrlParameters.Keys) {
        $queryValues.Add($key, $UrlParameters[$key])
    }

    $queryValues.Add("api-version", "2019-06-17")

    $uri += "?" + $queryValues.ToString()

    Write-Verbose "Invoking $uri"

    # expand arrays to individual objects
    $res = Invoke-RestMethod -Uri $uri
    foreach ($value in $res) {
        $value
    }
}