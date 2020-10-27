function Add-Path
{
    <#

.SYNOPSIS
Adds string to the PATH environment variable

.DESCRIPTION
Adds string to the PATH environment variable

#>
    param([string] $Path)

    $Env:PATH += ":$Path"
}


function InitializeModules
{
    $modules = @(
        "posh-git"
        "oh-my-posh", # includes also posh-git
        "PowerGit"
        "posh-with",
        "TabExpansionPlusPlus",
        "ZLocation",
        "JiraPS"
    )

    $linuxOnlyModules = @(
        "Microsoft.PowerShell.UnixCompleters"
    )

    $windowsOnlyModules = @(
        "CredentialManager"
    )

    if ($IsLinux)
    {
        $modules += $linuxOnlyModules
    }

    if ($IsWindows)
    {
        $modules += $windowsOnlyModules
    }

    $installed = (Get-InstalledModule).Name ?? @()
    $toInstall = Compare-Object $modules $installed | Where-Object {$_.SideIndicator -eq "<=" } | ForEach-Object { $_.InputObject }

    if ($toInstall)
    {
        "Installing missing modules: $toInstall"
        Install-Module $toInstall
    }

    # we need to import posh-git first and then PowerGit, so that its commands do not get overriden
    Import-Module posh-git
    Import-Module PowerGit

    Add-Path ~/.emacs.d/bin

    Set-Theme Paradox
    Set-PSReadLineOption -EditMode Vi
    Set-PSReadLineOption -ViModeIndicator Cursor
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
}

function LinuxSetup
{
    Add-Path ~/bin
    Add-Path ~/.config/composer/vendor/bin/
    Add-Path ~/.gem/ruby/2.7.0/bin/
    Add-Path ~/.dotnet/tools/
    Add-Path /usr/local/texlive/2020/bin/x86_64-linux

    $Env:EDITOR="$(which runemacs) -t -a vim"
    $Env:VISUAL="$(which runemacs) -c -a 'emacs'"

    $Env:SUDO_EDITOR="$(which emacsclient) -t -a vim"
}

# Override out-default to save the command output to a global variable $it
function Out-Default {
    [CmdletBinding(ConfirmImpact = 'Medium')]
    param(
        [Parameter(ValueFromPipeline)]
        [PSObject] $InputObject
    )

    begin{
        $wrappedCmdlet = $ExecutionContext.InvokeCommand.GetCmdlet('Out-Default')
        $sp = { & $wrappedCmdlet @PSBoundParameters }.GetSteppablePipeline()
        $sp.Begin($PSCmdlet)

        $it = @()
    }
    process{
        $sp.Process($_)
        $it += $_
    }
    end{
        $sp.End()
        $global:it = $it
    }
}

function emc { runemacs $args -a emacs }
function emt { runemacs -t $args -a vim }
function magit { runemacs -c -t -e "(progn (magit-status) (delete-other-windows))" }

InitializeModules

# overwrite Get-VcsStatus to use correct Get-GitStatus function
function Get-VcsStatus {
    $global:GitStatus = posh-git\Get-GitStatus
    return $global:GitStatus
}

if ($IsLinux)
{
    LinuxSetup
}

if (Test-Path -PathType Leaf $PSScriptRoot/local.ps1)
{
    . $PSScriptRoot/local.ps1
}

function Watch-File
{
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

    try
    {
        # start watching
        Write-Host "Watching..."
        $watcher.EnableRaisingEvents = $true
        $watcher
        while ($true) { Start-Sleep -Milliseconds 200 }
    }
    finally
    {
        # cleanup
        $watcher.EnableRaisingEvents = $false
        $watcher.Dispose()
    }
}

. $PSScriptRoot/Trace-Dotnet.ps1
