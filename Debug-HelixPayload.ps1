function Debug-HelixPayload {
    [CmdletBinding()]
    [Alias('dhp')]
    param(
        # Path to the helix payload directory
        [Parameter()]
        [string] $Path = $pwd,

        # Debugger to use for debugging
        [Parameter()]
        [ValidateSet('dotnet-dump', 'lldb', 'windbg')]
        [string] $Debugger = 'dotnet-dump'
    )

    if ($IsWindows) {
        $coreFile = Get-ChildItem -Recurse -Path $Path -Filter "*.dmp"
    }
    else {
        $coreFile = Get-ChildItem -Recurse -Path $Path -Filter "core.*"
    }

    # We need a path like $Path/shared/Microsoft.NETCore.App/7.0.0, there should be only one directory
    $hostPath = Join-Path $Path "shared/Microsoft.NETCore.App"
    $hostPath = Get-ChildItem $hostPath | Select-Object -First 1 -ExpandProperty FullName

    switch ($Debugger) {
        'dotnet-dump' {
            Write-Verbose "dotnet-dump analyze $coreFile --command `"setclrpath $hostPath`" `"setsymbolserver -directory $hostPath`""
            dotnet-dump analyze $coreFile --command "setclrpath $hostPath" "setsymbolserver -directory $hostPath"
        }
        'lldb' {
            $exePath = Get-Item (Join-Path $hostPath "dotnet*")
            Write-Verbose "lldb --core $coreFile $exePath -o `"setclrpath $hostPath`" -o `"setsymbolserver -directory $hostPath`""
            lldb --core $coreFile $exePath -o "setclrpath $hostPath" -o "setsymbolserver -directory $hostPath"
        }
        'windbg' {
            $exePath = Get-Item (Join-Path $hostPath "dotnet*")
            Write-Verbose "`"C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\windbg.exe`" -i $exePath -c `"!setclrpath $hostPath; !setsymbolserver -directory $hostPath`" -z $coreFile"
            &"C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\windbg.exe" -i $exePath -c "!setclrpath $hostPath; !setsymbolserver -directory $hostPath" -z $coreFile
        }
    }
}