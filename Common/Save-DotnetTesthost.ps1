function Save-DotnetTesthost {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Name,

        [Parameter()]
        [ValidateSet('8.0', '9.0', '10.0')]
        [string] $Framework = $global:RuntimeLatestFramework,

        # Path to the dotnet/runtime repo
        [Parameter()]
        [string] $RuntimeSourcesRoot = $global:RuntimeSourcesRoot
    )
    if ($IsWindows) {
        $OS = "windows"
    }
    elseif ($IsLinux) {
        $OS = "linux"
    }
    elseif ($IsOSX) {
        $OS = "osx"
    }

    $dir = Join-Path $RuntimeSourcesRoot "artifacts\bin\testhost\net$Framework-$OS-Release-x64\shared\Microsoft.NETCore.App"


    $src = Join-Path $dir "$Framework.0"
    $dst = Join-Path $dir $Name

    if (Test-Path $dst) {
        Remove-Item -Recurse -Force $dst
    }

    Copy-Item -Recurse $src $dst
}