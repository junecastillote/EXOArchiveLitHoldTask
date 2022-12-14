
Function SayError {
    param(
        $Text
    )
    $originalForegroundColor = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = 'Red'
    "$(Get-Date -Format 'dd-MMM-yyyy HH:mm:ss') : [ERROR] - $Text" | Out-Default
    $Host.UI.RawUI.ForegroundColor = $originalForegroundColor
}

Function SayInfo {
    param(
        $Text
    )
    $originalForegroundColor = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = 'Green'
    "$(Get-Date -Format 'dd-MMM-yyyy HH:mm:ss') : [INFO] - $Text" | Out-Default
    $Host.UI.RawUI.ForegroundColor = $originalForegroundColor
}

Function SayWarning {
    param(
        $Text
    )
    $originalForegroundColor = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = 'Red'
    "$(Get-Date -Format 'dd-MMM-yyyy HH:mm:ss') : [WARNING] - $Text" | Out-Default
    $Host.UI.RawUI.ForegroundColor = $originalForegroundColor
}

Function Say {
    param(
        $Text
    )
    $originalForegroundColor = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = 'Cyan'
    $Text | Out-Default
    $Host.UI.RawUI.ForegroundColor = $originalForegroundColor
}