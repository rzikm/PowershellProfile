function Use-DotnetRoot
{
    [CmdletBinding()]
    param(
        # path to the dotnet_root folder
        [Parameter(Mandatory)]
        [string] $DotnetRoot,

        # solution to open
        [Parameter()]
        [string] $SolutionPath
    )

    # This tells .NET Core to use the dotnet.exe in the DotnetRoot directory
    $Env:DOTNET_ROOT=$DotnetRoot

    # This tells .NET Core not to go looking for .NET Core in other places
    $Env:DOTNET_MULTILEVEL_LOOKUP=0

    # Put our local dotnet.exe on PATH first so Visual Studio knows which one to use
    if ($IsWindows)
    {
        $Env:PATH="$DotnetRoot;$($Env:PATH)"
    }
    if ($IsLinux)
    {
        $Env:PATH="$($DotnetRoot):$($Env:PATH)"
    }
}
