function Set-EnvironmentVariable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Name,

        [Parameter(Mandatory)]
        [string] $Value,

        # If set, the variable will be set machine-wide and persisted. Windows only.
        [Parameter()]
        [ValidateSet("Process", "User", "Machine")]
        [string] $Scope = "Process"
    )

    [Environment]::SetEnvironmentVariable($Name, $Value, $Scope)
}

function Append-EnvironmentVariable {
    <#

.SYNOPSIS
Appends string to the specified environment variable

.DESCRIPTION
Appends string to the specified environment variable

#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Name,

        [Parameter(Mandatory)]
        [string] $Value,

        [Parameter()]
        [switch] $Prepend,

        [Parameter()]
        [ValidateSet("Process", "User", "Machine")]
        [string] $Scope = "Process"
    )

    if ($IsLinux) {
        $separator = ":"
    }
    if ($IsWindows) {
        $separator = ";"
    }

    $newValue = [Environment]::GetEnvironmentVariable($Name, $Scope)

    if ($Prepend) {
        $newValue = "$Value$separator$newValue"
    }
    else {
        $newValue += "$separator$Value"
    }

    Set-EnvironmentVariable -Name $Name -Value $newValue -Scope $Scope
}

function Add-EnvironmentPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [Parameter()]
        [switch] $Prepend
    )

    if (!(Test-Path $Path)) {
        # path does not exist
        return;
    }

    $Path = Resolve-Path $Path

    Append-EnvironmentVariable -Name "PATH" -Value $Path -Prepend:$Prepend
}

if ($IsLinux) {
    function Add-LdLibraryPath {
        <#

    .SYNOPSIS
    Appends string to the PATH environment variable

    .DESCRIPTION
    Appends string to the PATH environment variable

    #>
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string] $Path,

            [Parameter()]
            [switch] $Prepend
        )

        if (!(Test-Path $Path)) {
            # path does not exist
            return;
        }

        $Path = Resolve-Path $Path

        Append-EnvironmentVariable "LD_LIBRARY_PATH" -Value $Path -Prepend:$Prepend
    }
}

function InitializeModules {
    $modules = @(
        "posh-with",
        "TabExpansionPlusPlus",
        "ZLocation",
        "posh-git"
    )

    $linuxOnlyModules = @(
        "Microsoft.PowerShell.UnixCompleters"
    )

    $windowsOnlyModules = @(
        "CredentialManager"
    )

    if ($IsLinux) {
        $modules += $linuxOnlyModules
    }

    if ($IsWindows) {
        $modules += $windowsOnlyModules
    }

    $installed = (Get-InstalledModule).Name ?? @()
    $toInstall = Compare-Object $modules $installed | Where-Object { $_.SideIndicator -eq "<=" } | ForEach-Object { $_.InputObject }

    if ($toInstall) {
        "Installing missing modules: $toInstall"
        Install-Module $toInstall -AllowClobber
    }
}

# Override out-default to save the command output to a global variable $it
function Out-Default {
    [CmdletBinding(ConfirmImpact = 'Medium')]
    param(
        [Parameter(ValueFromPipeline)]
        [PSObject] $InputObject
    )

    begin {
        $wrappedCmdlet = $ExecutionContext.InvokeCommand.GetCmdlet('Out-Default')
        $sp = { & $wrappedCmdlet @PSBoundParameters }.GetSteppablePipeline()
        $sp.Begin($PSCmdlet)

        $it = @()
    }
    process {
        $sp.Process($_)
        $it += $_
    }
    end {
        $sp.End()
        $global:it = $it
    }
}

function Watch-File {
    param(
        # Filter for file names
        [Parameter(Mandatory = $true)]
        [string[]] $Filters,
        # Script to call on changed files.
        [Parameter(Mandatory = $true)]
        [scriptblock] $ScriptBlock,
        # Filter for file system events
        [Nullable[System.IO.NotifyFilters]] $NotifyFilter = $null,
        # Directory to watch. Defaults to current directory.
        [string] $Directory = $pwd
    )

    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $Directory
    $Filters | ForEach-Object { $watcher.Filters.Add($_) }
    $watcher.IncludeSubdirectories = $true
    if ($NotifyFilter) { $watcher.NotifyFilter = $NotifyFilter }

    # we need to use MessageData to pass arguments to the action block
    Register-ObjectEvent $watcher "Changed" -MessageData $ScriptBlock -Action {
        Invoke-Command $Event.MessageData | Out-Host
    } > $null

    try {
        # start watching
        Write-Host "Watching..."
        $watcher.EnableRaisingEvents = $true
        $watcher
        while ($true) { Start-Sleep -Milliseconds 200 }
    }
    finally {
        # cleanup
        $watcher.EnableRaisingEvents = $false
        $watcher.Dispose()
    }
}

function Watch-Command {
    param(
        [scriptblock] $Command,
        [scriptblock] $ScriptBlock,
        [int32] $Delay = 1,
        [switch] $UntilTrue
    )

    $output = & $Command

    while ($true) {
        if ([bool]$output -and $UntilTrue) {
            & $ScriptBlock
        }

        Start-Sleep $Delay

        $newOutput = & $Command

        if (!$UntilTrue) {
            $diff = Compare-Object $output $newOutput
            if ($diff) {
                & $ScriptBlock
            }
        }

        $output = $newOutput
    }
}

function ShowDiff {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position = 1)]
        [AllowEmptyString()]
        [string[]] $DifferenceObject,

        [Parameter(Mandatory, Position = 0)]
        [AllowEmptyString()]
        [string[]] $ReferenceObject
    )

    $compare = Compare-Object -ReferenceObject $ReferenceObject -DifferenceObject $DifferenceObject
    $rights = @($compare | Where-Object { $_.sideindicator -eq "=>" })
    $lefts = @($compare | Where-Object { $_.sideindicator -eq "<=" })
    foreach ($right in $rights) {
        "$($right.InputObject) `t $($right.SideIndicator)  $($lefts[($Rights.IndexOf($right))].InputObject) `t $($lefts[($Rights.IndexOf($right))].SideIndicator)"
    }
}

function CompareDirectories {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [System.IO.DirectoryInfo] $Reference,

        [Parameter(Mandatory)]
        [System.IO.DirectoryInfo] $Target
    )

    $ref = Get-ChildItem -Recurse $Reference | Sort-Object -Property FullName
    $tgt = Get-ChildItem -Recurse $Target | Sort-Object -Property FullName

    $refRelative = $ref | ForEach-Object { [System.IO.Path]::GetRelativePath($Reference.FullName, $_) }
    $tgtRelative = $tgt | ForEach-Object { [System.IO.Path]::GetRelativePath($Target.FullName, $_) }

    $diff = Compare-Object -ReferenceObject $refRelative -DifferenceObject $tgtRelative
    if ($diff) {
        Write-Host "File names differ:"
        $diff
    }

    foreach ($file in $refRelative) {
        $refFile = Get-Item (Join-Path $Reference $file)
        $tgtFile = Get-Item (Join-Path $Target $file) -ErrorAction SilentlyContinue

        if (!$tgtFile) {
            # File does not exist in target
            continue;
        }

        if ((Get-FileHash $refFile).Hash -ne (Get-FileHash $tgtFile).Hash) {
            Write-Host "File $file differs"
        }
    }
}

function TransformWslPaths {
    [CmdletBinding()]
    param(
        [string[]] $Paths
    )

    foreach ($path in $Paths) {
        wsl wslpath -u -- $path.Replace('\', '/')
    }
}

# load stuff only when running in interactive mode to speed up stuff
if (!($MyInvocation.ScriptName)) {
    # PowerShell parameter completion shim for the dotnet CLI
    Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
        param($commandName, $wordToComplete, $cursorPosition)
        dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }

    if ($IsLinux) {
        Add-EnvironmentPath ~/bin
        Add-EnvironmentPath ~/.dotnet/tools/
        Add-EnvironmentPath ~/.config/emacs/bin
        Add-EnvironmentPath ~/.local/bin
        Add-EnvironmentPath ~/.cargo/bin

        $emacsclient = Get-Command emacsclient -ErrorAction SilentlyContinue

        if ($emacsclient) {
            $Env:EDITOR = "$(which emacsclient) -t -a emacs"
            $Env:VISUAL = "$(which emacsclient) -c -a emacs"

            $Env:SUDO_EDITOR = "$(which emacsclient) -t -a vim"

            function emc { emacsclient $args -a emacs }
            function emt { emacsclient -t $args -a vim }
            function magit { emacsclient -c -t -e "(progn (magit-status) (delete-other-windows))" }
        }

        if ((uname -r) -match 'WSL') {
            # Setup X server display
            $ENV:DISPLAY = (ip route list default | awk '{print $3}') + ":0"
        }
    }

    if ($IsWindows) {
        function emc { emacsclient $args }
        function magit { emacsclient -c -t -e "(progn (magit-status) (delete-other-windows))" }

        Add-EnvironmentPath "~/.emacs.d/bin"
    }

    oh-my-posh init pwsh --config $PSScriptRoot/theme.omp.json | Invoke-Expression

    . $PSScriptRoot/Send-GradingEmails.ps1

    . $PSScriptRoot/PSReadLineConfig.ps1

    # Helper cmdlets for work
    . $PSScriptRoot/Trace-Dotnet.ps1
    . $PSScriptRoot/Use-DotnetRoot.ps1
    . $PSScriptRoot/Open-VSSolution.ps1
    . $PSScriptRoot/Build-DotnetRuntime.ps1
    . $PSScriptRoot/Run-DotnetBenchmark.ps1
    . $PSScriptRoot/DotnetDevUtils.ps1
    . $PSScriptRoot/Get-HelixPayload.ps1
    . $PSScriptRoot/Invoke-HelixApi.ps1
    . $PSScriptRoot/Find-HelixWorkItem.ps1
    . $PSScriptRoot/Get-HelixJob.ps1
    . $PSScriptRoot/Get-HelixWorkItem.ps1
    . $PSScriptRoot/Get-HelixWorkItemDetail.ps1
    . $PSScriptRoot/Debug-HelixPayload.ps1
    . $PSScriptRoot/Test-DotnetLibrary.ps1
    . $PSScriptRoot/Install-Dotnet.ps1
    . $PSScriptRoot/Run-DotnetTesthost.ps1
    . $PSScriptRoot/DotnetSuggestShim.ps1
    . $PSScriptRoot/Run-HttpClientBenchmark.ps1

    if ($IsWindows) {
        . $PSScriptRoot/Invoke-Perfview.ps1
        . $PSScriptRoot/Update-SessionEnvironment.ps1
    }

    Import-Module posh-git

    if (Test-Path -PathType Leaf $PSScriptRoot/local.ps1) {
        . $PSScriptRoot/local.ps1
    }
}
