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

    . $PSScriptRoot/PSReadLineConfig.ps1
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

function Watch-Command
{
    param(
        [scriptblock] $Command,
        [scriptblock] $ScriptBlock,
        [int32] $Delay = 1,
        [switch] $UntilTrue
    )

    $output = & $Command

    while ($true)
    {
        if ([bool]$output -and $UntilTrue)
        {
            & $ScriptBlock
        }

        Start-Sleep $Delay

        $newOutput = & $Command

        if (!$UntilTrue)
        {
            $diff = Compare-Object $output $newOutput
            if ($diff)
            {
                & $ScriptBlock
            }
        }

        $output = $newOutput
    }
}

. $PSScriptRoot/Trace-Dotnet.ps1
. $PSScriptRoot/Use-DotnetRoot.ps1

# PowerShell parameter completion shim for the dotnet CLI
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
     param($commandName, $wordToComplete, $cursorPosition)
         dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
         }
 }

function SendGradingEmails
{
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        # Org file with comments for each student
        [Parameter(Mandatory)]
        [string] $Filename,

        # Subject of the email
        [Parameter(Mandatory)]
        [string] $Subject,

        # Prefix to the body of the email
        [Parameter()]
        [string] $PreBody = "Zdravím,`n",

        # Suffix to the body
        [Parameter()]
        [string] $PostBody = "`nRadek"
    )

    $EmailFrom = "r.zikmund.rz@gmail.com"
    $SMTPServer = "smtp.gmail.com"

    $SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587)
    $SMTPClient.EnableSsl = $true
    $creds = Get-StoredCredential -Target gmail-app-personal
    $SMTPClient.Credentials = New-Object System.Net.NetworkCredential -ArgumentList $creds.UserName, $creds.Password

    $m = Get-Content -raw $Filename | Select-String '\* .*\t(?<mail>.*)(?<body>[^*]+)' -AllMatches
    $m.Matches | ForEach-Object {
        $mail = $_.Groups[1].Value.Trim()
        $body = $PreBody + $_.Groups[2].Value + $PostBody

        $mail

        if ($Force -or $PSCmdlet.ShouldProcess("Send mail to '$mail':`n$body"))
        {
            $mm = New-Object System.Net.Mail.MailMessage
            $mm.From = New-Object System.Net.Mail.MailAddress -ArgumentList $EmailFrom
            $mm.To.Add((New-Object System.Net.Mail.MailAddress -ArgumentList $mail))
            $mm.Subject = $Subject
            $mm.Body = $body

            $SMTPClient.Send($mm)
            $mm.Dispose()
        }
    }

    $SMTPClient.Dispose();
}
