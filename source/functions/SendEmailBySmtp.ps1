Function SendEmailBySmtp {
    [cmdletbinding()]
    param (
        [parameter(Mandatory)]
        [string]$SmtpServer,

        [parameter()]
        [int]$Port,

        [parameter()]
        [switch]$UseSSL,

        [parameter()]
        [pscredential]$Credential,

        [parameter(Mandatory)]
        [mailaddress]$From,

        [parameter(Mandatory)]
        [mailaddress[]]$To,

        [parameter()]
        [mailaddress[]]$CC,

        [parameter()]
        [mailaddress[]]$BCC,

        [parameter(Mandatory)]
        [string]$Subject,

        [parameter(Mandatory)]
        [string]$Body,

        [parameter()]
        [string[]]$Attachments
    )

    $mailParams = @{
        SmtpServer                 = $smtpServer
        To                         = $To
        From                       = $From
        Subject                    = $Subject
        DeliveryNotificationOption = 'OnFailure'
        BodyAsHTML                 = $true
        Body                       = $(ReplaceSmartCharacter $Body)
    }

    if ($Port) { $mailParams += @{Port = $Port } }
    if ($Credential) { $mailParams += @{Credential = $Credential } }
    if ($PSBoundParameters.ContainsKey('UseSSL')) { $mailParams += @{UseSSL = $true } }
    if ($Attachments) { @{Attachments = $Attachments } }

    try {
        Send-MailMessage @mailParams -ErrorAction Stop -WarningAction SilentlyContinue
    }
    catch {
        SayError "Send email failed: $($_.Exception.Message)"
    }
}