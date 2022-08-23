[CmdletBinding()]
param (
    [string]$ModulePath
)
$moduleManifest = Test-ModuleManifest -Path $((Get-ChildItem -Path $PSScriptRoot -Filter *.psd1).FullName)
$module = @(Get-Module ($moduleManifest.Name) -ListAvailable | Where-Object { $_.Version -eq $moduleManifest.Version })

if ($module.Count -gt 0) {
    foreach ($Moduleinfo in $module) {
        $ModulePath = $Moduleinfo.ModuleBase
        try {
            Remove-Item -Path $ModulePath -Recurse -Force -Confirm:$false -ErrorAction Stop
            Write-Output "Done uninstalling $($Moduleinfo.Name) version $($Moduleinfo.Version) from $($Moduleinfo.ModuleBase)"
        }
        catch {
            Write-Output ""
            Write-Output "Failed"
            Write-Output $_.Exception.Message
            Write-Output ""
            return $null
        }
    }
}