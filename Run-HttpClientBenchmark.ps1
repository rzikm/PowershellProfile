function Run-HttpClientBenchmark {
    [CmdletBinding()]
    param(
        # Target framework to use
        [Parameter()]
        [ValidateSet('net8.0', 'net9.0')]
        [string] $Framework = 'net9.0',

        # Profile to use
        [Parameter(Mandatory)]
        [ValidateSet('local', 'aspnet-perf-lin', 'aspnet-perf-win', 'aspnet-citrine-lin', 'aspnet-citrine-win', 'aspnet-citrine-amd2', 'aspnet-citrine-arm-line', 'aspnet-gold-lin', 'aspnet-gold-win')]
        [string] $RunProfile,

        # Number of iterations to run
        [Parameter()]
        [int] $Iterations,

        # Warmup in seconds
        [Parameter()]
        [int] $Warmup,

        # Duration in seconds
        [Parameter()]
        [int] $Duration,

        # Port on the server to connect to
        [Parameter]
        [int] $ServerPort,

        # Http version to use
        [Parameter()]
        [ValidateSet('1.1', '2.0', '3.0')]
        [string] $HttpVersion = '1.1',

        # Whether or not to use HTTPS, implied when HttpVersion is 3.0
        [Parameter()]
        [switch] $UseHttps,

        # Number of HttpClient instances on the client
        [Parameter()]
        [int] $Clients,

        # Number of concurrent threads per HttpClient instance
        [Parameter()]
        [int] $ConcurrencyPerClient,

        # Size of the server rsponse
        [Parameter()]
        [int] $ResponseSize,

        # Number of concurrent threads per HttpClient instance
        [Parameter()]
        [int] $Http3StreamLimit,

        [Parameter(ParameterSetname = "Get")]
        [switch] $Get,

        [Parameter(ParameterSetname = "Post")]
        [switch] $Post,

        # Path on the server to make requests to, defaults to /get or /post
        [Parameter()]
        [string] $Path,

        [Parameter(ParameterSetname = "Post")]
        [int] $RequestContentSize,

        [Parameter(ParameterSetname = "Post")]
        [int] $RequestContentWriteSize,

        [Parameter(ParameterSetname = "Post")]
        [switch] $RequestContentFlushAfterWrite,

        [Parameter(ParameterSetname = "Post")]
        [switch] $RequestContentUnknownLength,

        [Parameter()]
        [switch] $CollectClientTraces,

        [Parameter()]
        [switch] $CollectServerTraces,

        [Parameter()]
        [String[]] $ExtraFiles,

        [Parameter()]
        [string[]] $ClientExtraFiles,

        [Parameter()]
        [string[]] $ServerExtraFiles,

        [Parameter()]
        [Hashtable] $EnvVars,

        [Parameter()]
        [Hashtable] $ClientEnvVars,

        [Parameter()]
        [Hashtable] $ServerEnvVars,

        [Parameter()]
        [Hashtable] $Properties,

        [Parameter()]
        [string] $CsvOutput,

        # Timeout for the benchmark in seconds
        [Parameter()]
        [int] $Timeout = 60
    )

    $config = "https://raw.githubusercontent.com/aspnet/Benchmarks/main/scenarios/httpclient.benchmarks.yml"

    if ($Get) {
        $scenario = 'httpclient-kestrel-get'
        if (-not $Path) { $Path = '/get' }
    }
    elseif ($Post) {
        $scenario = 'httpclient-kestrel-post'
        if (-not $Path) { $Path = '/post' }
    }
    else {
        Write-Error "Either -Get or -Post must be specified"
    }

    $arguments = @(
        '--config', $config,
        '--scenario', $scenario,
        '--client.path', $Path,
        '--profile', $RunProfile
        '--client.timeout', $Timeout,
        '--server.timeout', $Timeout
        '--client.framework', $Framework,
        '--server.framework', $Framework
    )

    if ($Iterations -gt 1) {
        $arguments += @("--variable", "iterations=$Iterations")
    }

    if ($Warmup) {
        $arguments += @("--variable", "warmup=$Warmup")
    }

    if ($Duration) {
        $arguments += @("--variable", "duration=$Duration")
    }

    if ($ServerPort) {
        $arguments += @("--variable", "serverPort=$ServerPort")
    }

    if ($HttpVersion) {
        $arguments += @("--variable", "httpVersion=$HttpVersion")

        if ($HttpVersion -eq '3.0') {
            $UseHttps = $true
        }
    }

    if ($UseHttps) {
        $arguments += @("--variable", "useHttps=true")
    }

    if ($Clients) {
        $arguments += @("--variable", "numberOfHttpClients=$Clients")
    }

    if ($ConcurrencyPerClient) {
        $arguments += @("--variable", "concurrencyPerHttpClient=$ConcurrencyPerClient")
    }

    if ($ResponseSize) {
        $arguments += @("--variable", "responseSize=$ResponseSize")
    }

    if ($Http3StreamLimit) {
        $arguments += @("--variable", "http3StreamLimit=$Http3StreamLimit")
    }

    if ($RequestContentSize) {
        $arguments += @("--variable", "requestContentSize=$RequestContentSize")
    }

    if ($RequestContentWriteSize) {
        $arguments += @("--variable", "requestContentWriteSize=$RequestContentWriteSize")
    }

    if ($RequestContentFlushAfterWrite) {
        $arguments += @("--variable", "requestContentFlushAfterWrite=true")
    }

    if ($RequestContentUnknownLength) {
        $arguments += @("--variable", "requestContentUnknownLength=true")
    }

    if ($CollectClientTraces) {
        $arguments += @("--client.dotnetTrace", "true")
    }

    foreach ($file in $ExtraFiles) {
        $arguments += @("--client.options.outputFiles", $file)
    }

    foreach ($file in $ClientExtraFiles) {
        $arguments += @("--client.options.outputFiles", $file)
    }

    foreach ($key in $EnvVars.Keys) {
        $arguments += @("--client.environmentVariables", "$key=$($EnvVars[$key])")
    }

    foreach ($key in $ClientEnvVars.Keys) {
        $arguments += @("--client.environmentVariables", "$key=$($ClientEnvVars[$key])")
    }

    if ($CollectServerTraces) {
        $arguments += @("--server.dotnetTrace", "true")
    }

    foreach ($file in $ExtraFiles) {
        $arguments += @("--server.options.outputFiles", $file)
    }

    foreach ($file in $ServerExtraFiles) {
        $arguments += @("--server.options.outputFiles", $file)
    }

    foreach ($key in $EnvVars.Keys) {
        $arguments += @("--server.environmentVariables", "$key=$($EnvVars[$key])")
    }

    foreach ($key in $ServerEnvVars.Keys) {
        $arguments += @("--server.environmentVariables", "$key=$($ServerEnvVars[$key])")
    }

    foreach ($propKey in $Properties.Keys) {
        $arguments += @("--property", "$propKey=$($Properties[$propKey])")
    }

    if ($CsvOutput) {
        $arguments += @("--csv", $CsvOutput)
    }

    Write-Host "crank $arguments"
    crank @arguments
}