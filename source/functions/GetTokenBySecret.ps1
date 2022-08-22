Function GetTokenBySecret {
    [cmdletbinding()]
    param (
        [parameter(Mandatory)]
        [string]
        $ClientID,

        [parameter(Mandatory)]
        [string]
        $ClientSecret,

        [parameter(Mandatory)]
        [string]
        $TenantID
    )

    # Create the request splat
    $request = @{
        Body        = @{
            grant_type    = 'client_credentials'
            scope         = 'https://graph.microsoft.com/.default'
            client_id     = $ClientID
            client_secret = $ClientSecret
        }
        ContentType = 'application/x-www-form-urlencoded'
        Method      = 'POST'
        Uri         = "https://login.microsoftonline.com/$($TenantID)/oauth2/v2.0/token"
    }

    $oauth = Invoke-RestMethod @request
    $oauth | Add-Member -MemberType NoteProperty -Name TenantID -Value $TenantID
    $oauth | Add-Member -MemberType NoteProperty -Name ExpiresOn -Value $((Get-Date).AddSeconds($oauth.expires_in))
    return $oauth
}