function Enable-DotnetDump {
    [CmdletBinding()]
    param(
        # %%	A single % character
        # %p	PID of dumped process
        # %e	The process executable filename
        # %h	Host name return by gethostname()
        # %t	Time of dump, expressed as seconds since the Epoch, 1970-01-01 00:00:00 +0000 (UTC)
        [Parameter()]
        [string] $Name = "core.%e.%p",
        
        [Parameter()]
        [switch] $EnableMiniDump = $true,

        # 1	Mini	A small dump containing module lists, thread lists, exception information, and all stacks.
        # 2	Heap	A large and relatively comprehensive dump containing module lists, thread lists, all stacks, exception information, handle information, and all memory except for mapped images.
        # 3	Triage	Same as Mini, but removes personal user information, such as paths and passwords.
        # 4	Full	The largest dump containing all memory including the module images.
        [Parameter()]
        [ValidateSet("Mini", "Heap", "Triage", "Full")]
        [string] $MiniDumpType = "Full",
        
        [Parameter()]
        [switch] $CrashReport,
        
        [Parameter()]
        [switch] $CreateDumpVerboseDiagnostics
    )

    function SwitchToString($switch) {
        if ($switch) {
            return "1"
        }
        return "0"
    }

    $ENV:DOTNET_DbgEnableMiniDump = SwitchToString $EnableMiniDump
    $ENV:DOTNET_DbgMiniDumpType = $MiniDumpType
    $ENV:DOTNET_DbgMiniDumpName = $Name
    $ENV:DOTNET_EnableCrashReport = SwitchToString $CrashReport
    $ENV:DOTNET_CreateDumpVerboseDiagnostics = SwitchToString $CreateDumpVerboseDiagnostics
}