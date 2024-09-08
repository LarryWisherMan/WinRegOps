<#
.SYNOPSIS
Opens a registry hive on the local computer.

.DESCRIPTION
This function opens a registry hive on the local computer using the Microsoft.Win32.RegistryKey::OpenBaseKey method. It allows you to specify the registry hive and view (32-bit or 64-bit). By default, it uses the local machine view.

.PARAMETER RegistryHive
Specifies the registry hive to open (e.g., HKEY_LOCAL_MACHINE, HKEY_CURRENT_USER).

.PARAMETER RegistryView
Specifies the registry view to open (32-bit or 64-bit). Defaults to the system's default view (64-bit on a 64-bit OS, 32-bit on a 32-bit OS).

.OUTPUTS
Microsoft.Win32.RegistryKey
The registry key object representing the opened registry hive.

.EXAMPLE
Get-OpenBaseKey -RegistryHive 'HKEY_LOCAL_MACHINE'

Opens the HKEY_LOCAL_MACHINE hive on the local computer using the default registry view.

.EXAMPLE
Get-OpenBaseKey -RegistryHive 'HKEY_LOCAL_MACHINE' -RegistryView 'RegistryView32'

Opens the HKEY_LOCAL_MACHINE hive on the local computer using the 32-bit view of the registry.

.NOTES
This function is a wrapper around the Microsoft.Win32.RegistryKey::OpenBaseKey method, providing an easier interface for opening registry hives locally.
#>
function Get-OpenBaseKey {
    param (
        [Microsoft.Win32.RegistryHive]$RegistryHive,
        [Microsoft.Win32.RegistryView]$RegistryView = [Microsoft.Win32.RegistryView]::Default
    )
    return [Microsoft.Win32.RegistryKey]::OpenBaseKey($RegistryHive, $RegistryView)
}
