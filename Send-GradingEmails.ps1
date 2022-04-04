function Send-GradingEmails {
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
        [string] $PostBody = "`nRadek",

        # AttachmentFileName
        [Parameter()]
        [string] $AttachmentFileName
    )

    $EmailFrom = "r.zikmund.rz@gmail.com"
    $SMTPServer = "smtp.gmail.com"

    $SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587)
    $SMTPClient.EnableSsl = $true
    $creds = CredentialManager\Get-StoredCredential -Target gmail-app-personal
    $SMTPClient.Credentials = New-Object System.Net.NetworkCredential -ArgumentList $creds.UserName, $creds.Password

    $m = Get-Content -raw $Filename | Select-String '\* [^@]*\t(?<mail>[^\t\n]+)(\t(?<dir>.+))?(?<body>[^*]+)\r?\n?' -AllMatches
    $m.Matches | ForEach-Object {
        $mail = [PsCustomObject]@{
            mail = $_.Groups['mail'].Value.Trim()
            body = $PreBody + $_.Groups['body'].Value.Trim() + $PostBody
        }

        if ($AttachmentFileName) {
            $attachmentFile = Get-Item (Join-Path (Split-Path -Parent $Filename) $dir $AttachmentFileName)
        }

        $msg = "Send mail`nto: '$($mail.mail)'`nMessage:`n$($mail.body)"

        if ($AttachmentFileName) {
            $msg += "`nWith attachment: $attachmentFile"
        }

        if ($Force -or $PSCmdlet.ShouldProcess($msg)) {
            $mm = New-Object System.Net.Mail.MailMessage
            $mm.From = New-Object System.Net.Mail.MailAddress -ArgumentList $EmailFrom
            $mm.To.Add((New-Object System.Net.Mail.MailAddress -ArgumentList ($mail.mail)))
            $mm.Subject = $Subject
            $mm.Body = $mail.body

            # if ($AttachmentFileName)
            # {
            #     $mm.Attachments.Add([System.Net.Mail.Attachment]::new($attachmentFile.FullName))
            # }

            $SMTPClient.Send($mm)
            $mm.Dispose()
        }
    }

    $SMTPClient.Dispose();
}
