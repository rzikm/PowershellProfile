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
        "posh-git",
        "oh-my-posh",
        "Posh-With",
        "TabExpansionPlusPlus",
        "ZLocation"
    )

    $linuxOnlyModules = @(
        "Microsoft.PowerShell.UnixCompleters"
    )

    if ($IsLinux)
    {
        $modules += $linuxOnlyModules
    }

    $installed = (Get-InstalledModule).Name
    $toInstall = (Compare-Object $modules $installed | Where-Object { $_.SideIndicator -eq "<=" } ).InputObject

    if ($toInstall)
    {
        "Installing missing modules: $toInstall"
        Install-Module $toInstall
    }

    Import-Module $modules

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


function emc { runemacs $args -a emacs }
function emt { runemacs -t $args -a vim }
function magit { emacsclient -c -t -e "(progn (magit-status) (delete-other-windows))" }

InitializeModules

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
