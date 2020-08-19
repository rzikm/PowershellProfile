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

    $installed = Get-InstalledModule | ForEach-Object { $_.Name }
    $toInstall = Compare-Object $modules $installed | Where-Object {$_.SideIndicator -eq "<=" } | ForEach-Object { $_.InputObject }

    if ($toInstall)
    {
        "Installing missing modules"
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
    $Env:EDITOR="$(which runemacs) -t -a vim"
    $Env:VISUAL="$(which runemacs) -c -a 'emacs'"

    $Env:SUDO_EDITOR="$(which emacsclient) -t -a vim"

    Add-Path ~/bin
    Add-Path ~/.config/composer/vendor/bin/
    Add-Path ~/.gem/ruby/2.7.0/bin/
    Add-Path ~/.dotnet/tools/
    Add-Path /usr/local/texlive/2020/bin/x86_64-linux
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
