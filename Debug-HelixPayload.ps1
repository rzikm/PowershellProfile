function Debug-HelixPayload {
    [CmdletBinding()]
    [Alias('dhp')]
    param(
        # Path to the helix payload directory
        [Parameter()]
        [string] $Path = $pwd,

        # Debugger to use for debugging
        [Parameter()]
        [ValidateSet('dotnet-dump', 'lldb')]
        [string] $Debugger = 'dotnet-dump'
    )

    $coreFile = Get-ChildItem -Recurse -Path $Path -Filter "core.*"

    # We need a path like $Path/shared/Microsoft.NETCore.App/7.0.0, there should be only one directory
    $hostPath = Join-Path $Path "shared/Microsoft.NETCore.App"
    $hostPath = Get-ChildItem $hostPath | Select-Object -First 1 -ExpandProperty FullName

    switch ($Debugger) {
        'dotnet-dump' {  
            dotnet-dump analyze $coreFile --command "setclrpath $hostPath" "setsymbolserver -directory $hostPath"
        }
        'lldb' {
            lldb --core $coreFile (Join-Path $hostPath "dotnet") -o "setclrpath $hostPath" -o "setsymbolserver -directory $hostPath"
        }
    }
}