# Function to disable the litigation hold status of ineligible (without Enterprise Mailbox Plan) mailboxes.
Function Disable-ExoInvalidLitigationHoldStatus {
    [cmdletbinding()]
    Param(
        [parameter()]
        [boolean]$TestMode = $true,

        [parameter()]
        [string[]]$ExclusionList = @()
    )

    Say ""
    SayInfo "=====Disable Litigation Hold of non-eligible Exchange Online Mailbox====="

    $thisModule = $MyInvocation.MyCommand.Module
    $tz = ([System.TimeZoneInfo]::Local).DisplayName.ToString().Split(" ")[0]
    $today = Get-Date -Format "MMMM dd, yyyy hh:mm tt"
    $css_string = Get-Content $([System.IO.Path]::Combine($thisModule.ModuleBase, 'source', 'css', 'style.css')) -Raw

    # Test if Exchange Online PowerShell session is established
    try {
        $OrgInfo = Get-OrganizationConfig -Erroraction stop
        $Organization = $OrgInfo.DisplayName
    }
    catch {
        SayError "Remote Exchange Online PowerShell Session is required. Connect to Exchange Online first and try again."
        break
    }

    if ($TestMode) {
        SayInfo "TestMode is specified. Running on test mode only. No changes will be made."
    }

    SayInfo 'Getting mailbox list without Exchange Online Enterprise mailbox plan but Litigation Hold-enabled.'

    # Get all mailboxes with ExchangeOnlineEnterprise plans
    ## Get all ExchangeOnlineEnterprise plans and enclose each DN in single quotes
    ## I don't really know if it's possible to have more than one ExchangeOnlineEnterprise mailbox plan in one org,
    ## but I choose to handle the possibility that it may happen.
    $mailboxPlan = @(Get-MailboxPlan 'ExchangeOnlineEnterprise' | Select-Object -ExpandProperty DistinguishedName | ForEach-Object { "'$_'" })
    ## Create the filter based on MailboxPlan and LitigationHoldEnabled property
    $filter = "(MailboxPlan -eq $($mailboxPlan -join " -OR MailboxPlan -eq ")) -AND litigationholdenabled -eq 'False'"

    $mailboxList = @(Get-Mailbox -ResultSize Unlimited -Filter $filter) |
    Select-Object @{n = 'Display Name'; e = { $_.DisplayName } },
    @{n = 'User ID'; e = { $_.UserPrincipalName } },
    @{n = 'Email Address'; e = { $_.PrimarySMTPAddress } },
    @{n = 'Mailbox Type'; e = { $_.RecipientTypeDetails } },
    @{n = 'Hold Enabled'; e = { $_.LitigationHoldEnabled } },
    @{n = 'Hold Duration'; e = { $_.LitigationHoldDuration } },
    @{n = 'Hold Owner'; e = { $_.LitigationHoldOwner } },
    @{n = 'Hold Date'; e = { '{0:yyyy/MM/dd}' -f $_.LitigationHoldDate } },
    @{n = 'Mailbox Created Date'; e = { '{0:yyyy/MM/dd}' -f $_.WhenMailboxCreated } },
    @{n = 'Excluded'; e = {
            if ($ExclusionList -contains $_.PrimarySMTPAddress -or $ExclusionList -contains $_.UserPrincipalName) {
                $true
            }
            else {
                $false
            }
        }
    } | Sort-Object 'Display Name'

    $excludeMailbox = @($mailboxList | Where-Object { $_.Excluded })
    $includeMailbox = @($mailboxList | Where-Object { !$_.Excluded })

    $excludeCount = $excludeMailbox.Count
    $includeCount = $includeMailbox.Count

    SayInfo "Found $($mailboxList.count) eligible mailbox without online archive mailbox."
    if ($excludeCount -gt 0) {
        SayInfo "But $excludeCount mailbox are in the exclusion list."
        $excludeMailbox | Where-Object { $_.Excluded } | Select-Object 'Display Name', 'Email Address', 'Archive GUID', 'Mailbox Created Date' | Export-Csv $outputExclusionCsvList -NoTypeInformation -Force
    }

    if ($includeCount -gt 0) {
        ## create the HTML report
        ## html title
        $html = "<html><head><title>[$($Organization)] $($subject)</title><http-equiv=""Content-Type"" content=""text/html; charset=ISO-8859-1"" />"
        $html += '<style type="text/css">'
        $html += $css_string
        $html += '</style></head><body>'

        ## heading
        $html += '<table id="tbl">'
        if ($TestMode) {
            $html += '<tr><td class="head">[!!! TEST MODE ONLY !!!] NO CHANGES WERE MADE IN THIS RUN.</td></tr>'
        }
        else {
            $html += '<tr><td class="head"></td></tr>'
        }
        $html += '<tr><th class="section">' + $subject + '</th></tr>'
        $html += '<tr><td class="head"><b>' + $Organization + '</b><br>' + $today + ' ' + $tz + '</td></tr>'
        $html += '<tr><td class="head"><i>**List of mailbox litigation hold enabled by this task.</i></td></tr>'
        $html += '</table>'
        $html += '<table id="tbl">'

        ## If CSV File Report
        if ($reportType -eq 'CSV') {
            $html += "<tr><td>Please see attached CSV report</td></tr>"
        }

        ## If HTML Table Report
        if ($reportType -eq 'HTML') {
            $html += '<tr><th>Name</th><th>Email Address</th><th>Mailbox Type</th><th>Hold Enabled</th><th>Hold Date</th><th>Mailbox Created Date</th></tr>'
        }

        ## Enable Litigation Hold
        for ($i = 0 ; $i -lt ($includeMailbox.Count); $i++) {
            if (!$TestMode) {
                Set-Mailbox -Identity $includeMailbox[$i].'User ID' -LitigationHoldEnabled $true -WarningAction SilentlyContinue
                $litHold = Get-Mailbox -Identity $includeMailbox[$i].'User ID' | Select-Object Litigationhold*
                $includeMailbox[$i].'Hold Enabled' = $lithold.LitigationHoldEnabled
                $includeMailbox[$i].'Hold Date' = $lithold.LitigationHoldDate
                $includeMailbox[$i].'Hold Owner' = $lithold.LitigationHoldOwner

                if ($lithold.LitigationHoldEnabled) {
                    SayInfo "$($includeMailbox[$i].'Display Name') - [OK]"
                }
                else {
                    SayWarning "$($includeMailbox[$i].'Display Name') - [NOT OK]"
                }
            }
            ## If HTML Table Report
            if ($reportType -eq 'HTML') {
                $html += "<tr><td>$($includeMailbox[$i].'Display Name')</td>"
                $html += "<td>$($includeMailbox[$i].'Email Address')</td>"
                $html += "<td>$($includeMailbox[$i].'Mailbox Type')</td>"
                $html += "<td>$($includeMailbox[$i].'Hold Enabled')</td>"
                $html += "<td>$('{0:yyyy/MM/dd}' -f $includeMailbox[$i].'Hold Date')</td>"
                $html += "<td>$($includeMailbox[$i].'Mailbox Created Date')</td>"
            }
        }
        $includeMailbox | Where-Object { !$_.Excluded } | Select-Object 'Display Name', 'Email Address', 'Mailbox Type', 'Hold Enabled', 'Hold Owner', 'Hold Date', 'Mailbox Created Date' | Export-Csv -NoTypeInformation $outputCsvFile -Force

        $html += '</table>'
        $html += '<table id="tbl">'
        $html += '<tr><td class="head"> </td></tr>'
        $html += '<tr><td class="head"> </td></tr>'
        $html += '<tr><td class="head">Source: ' + $env:COMPUTERNAME + '<br>'
        $html += 'Script Directory: ' + ($thisModule.ModuleBase) + '<br>'
        $html += 'Report Directory: ' + (Resolve-Path $ReportDirectory).Path + '<br>'
        $html += '<a href="' + $($thisModule.PrivateData.PSData.ProjectUri) + '">' + $($thisModule.Name) + ' v' + $($thisModule.Version.ToString()) + ' </a><br>'
        $html += '<tr><td class="head"> </td></tr>'
        $html += '</table>'
        $html += '</html>'
        $html | Out-File $outputHTMLFile -Encoding UTF8
        if ($ReportType -eq 'HTML') {
            SayInfo "HTML Report saved in $($outputHTMLFile)"
        }
        SayInfo "CSV Report saved in $($outputCsvFile)"
        if ($ExclusionList) {
            SayInfo "The list of excluded mailboxes can be found in $($outputExclusionCsvList)"
        }

        if ($smtpEmailParamsValid) {
            SayInfo 'Sending email..'
            $mailParams = @{
                SmtpServer = $SendEmailBySmtp['SmtpServer']
                To         = $SendEmailBySmtp['To']
                From       = $SendEmailBySmtp['From']
                Subject    = "[$($Organization)] $subject"
                Body       = (Get-Content $outputHTMLFile -Raw -Encoding UTF8)
            }

            if ($SendEmailBySmtp['Port']) { $mailParams += @{Port = $SendEmailBySmtp['Port'] } }
            if ($SendEmailBySmtp['Credential']) { $mailParams += @{Credential = $SendEmailBySmtp['Credential'] } }
            if ($SendEmailBySmtp['UseSSL']) { $mailParams += @{UseSSL = $SendEmailBySmtp['UseSSL'] } }

            $attachment_list = @()
            if ($reportType -eq 'CSV') { $attachment_list += $outputCsvFile }
            if ($excludeCount -gt 0) { $attachment_list += $outputExclusionCsvList }

            if ($attachment_list.count -gt 0) {
                $mailParams += @{Attachments = $attachment_list }
            }
            SendEmailBySmtp @mailParams
        }

        if ($graphEmailParamsValid) {
            SayInfo 'Sending email..'
            $mailParams = @{
                Token   = $OAuthToken.access_token
                From    = $SendEmailByGraph['From']
                To      = $SendEmailByGraph['To']
                Subject = "[$($Organization)] $subject"
                Body    = (Get-Content $outputHTMLFile -Raw -Encoding UTF8)
            }

            if ($SendEmailByGraph['CC']) { $mailParams += @{CC = $SendEmailByGraph['CC'] } }
            if ($SendEmailByGraph['BCC']) { $mailParams += @{BCC = $SendEmailByGraph['BCC'] } }


            $attachment_list = @()
            if ($reportType -eq 'CSV') { $attachment_list += $outputCsvFile }
            if ($excludeCount -gt 0) { $attachment_list += $outputExclusionCsvList }

            if ($attachment_list.count -gt 0) {
                $mailParams += @{Attachments = $attachment_list }
            }
            # Say $mailParams
            SendEmailByGraph @mailParams
        }
        return $($includeMailbox + $excludeMailbox)
    }
}