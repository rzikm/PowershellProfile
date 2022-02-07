function Open-VSSolution
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ArgumentCompleter( {
            param ($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
            $libsSrcPath = Join-Path $global:RuntimeSourcesRoot "src/libraries"
            Get-ChildItem $libsSrcPath -Filter "$wordToComplete*" | ForEach-Object Name
        } )]
        [string] $Solution,

        [Parameter()]
        [string] $RuntimeSourcesRoot = $global:RuntimeSourcesRoot
    )

    $buildCmd = Join-Path $RuntimeSourcesRoot 'build.cmd'
    &$buildCmd -vs $Solution
}
