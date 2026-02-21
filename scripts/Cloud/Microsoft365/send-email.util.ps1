<#
.SYNOPSIS
    Sends email via Office 365 SMTP server.

.DESCRIPTION
    This utility script provides examples of different methods to send email through
    Office 365 SMTP server. It demonstrates various approaches including using
    System.Net.Mail.SmtpClient and the Send-MailMessage cmdlet.
    
    This is a reference/utility script showing different email sending patterns.

.NOTES
    Author: Randy Bordeaux
    GitHub: https://github.com/bordera-randy
    Version: 1.0
    Requires: Valid Office 365 credentials
    
.LINK
    https://docs.microsoft.com/en-us/exchange/mail-flow-best-practices/how-to-set-up-a-multifunction-device-or-application-to-send-email-using-microsoft-365-or-office-365

.EXAMPLE
    Modify the variables in this script with your credentials and run it to send a test email.
#>

# Configure SMTP server settings for Office 365
$SMTPServer = "smtp.office365.com"
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587) 
$SMTPClient.EnableSsl = $true

# Email configuration - Update these values with your information
$EmailFrom = 'your-email@domain.com'
$EmailTo = "recipient@domain.com"
$EmailSubject = "Test Email from PowerShell"
$EmailBody = "<strong>This is a test HTML email sent from PowerShell</strong>"

# Credentials - Update with your Office 365 credentials
$emailusername = 'your-email@domain.com'
$emailPassword = 'your-app-specific-password'

# Set SMTP client credentials
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential("$emailusername", "$emailPassword")

# Alternative: Use Get-Credential for interactive credential prompt
# $Credential = Get-Credential

# Method 1: Using Send-MailMessage cmdlet with credential object
# Uncomment and modify as needed
<#
$Credential = Get-Credential
$mailparams = @{
    SmtpServer  = $SMTPServer
    Port        = '587'
    UseSsl      = $true 
    Credential  = $Credential
    From        = $EmailFrom
    To          = $EmailTo
    Subject     = "SMTP Test Email - $(Get-Date -Format g)"
    Body        = "This is a test message from PowerShell"
}
Send-MailMessage @mailparams
#>

# Method 2: Using System.Net.Mail.MailMessage
$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $EmailSubject, $EmailBody)
$SMTPMessage.IsBodyHTML = $true  # Set to $false if you want plain text email

# Send the email
try {
    $SMTPClient.Send($SMTPMessage)
    Write-Host "Email sent successfully!" -ForegroundColor Green
}
catch {
    Write-Error "Failed to send email: $_"
}
finally {
    # Clean up
    if ($SMTPMessage) { $SMTPMessage.Dispose() }
    if ($SMTPClient) { $SMTPClient.Dispose() }
}

# Method 3: Using Send-MailMessage with inline credentials (for reference only)
# Note: Storing passwords in plain text is not recommended for production use
<#
$Credential = New-Object System.Management.Automation.PSCredential(
    $emailusername,
    (ConvertTo-SecureString $emailPassword -AsPlainText -Force)
)

Send-MailMessage -From $EmailFrom `
                 -To $EmailTo `
                 -SmtpServer smtp.office365.com `
                 -Port 587 `
                 -Subject $EmailSubject `
                 -Body $EmailBody `
                 -Credential $Credential `
                 -UseSsl `
                 -Verbose
#>
