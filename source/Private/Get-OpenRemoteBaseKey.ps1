<#
.SYNOPSIS
Opens a registry hive on a remote computer.

.DESCRIPTION
This function opens a registry hive on a remote computer using the Microsoft.Win32.RegistryKey::OpenRemoteBaseKey method. It allows you to specify the registry hive and the remote computer name. The remote computer must have the remote registry service running.

.PARAMETER RegistryHive
Specifies the registry hive to open (e.g., HKEY_LOCAL_MACHINE, HKEY_CURRENT_USER).

.PARAMETER ComputerName
Specifies the name of the remote computer on which the registry hive will be opened.

.OUTPUTS
Microsoft.Win32.RegistryKey
The registry key object representing the opened registry hive on the remote computer.

.EXAMPLE
Get-OpenRemoteBaseKey -RegistryHive 'HKEY_LOCAL_MACHINE' -ComputerName 'RemotePC'

Opens the HKEY_LOCAL_MACHINE hive on the remote computer 'RemotePC'.

.NOTES
This function is a wrapper around the Microsoft.Win32.RegistryKey::OpenRemoteBaseKey method, providing an easier interface for opening registry hives on remote computers. The remote registry service must be enabled on the target machine.
#>
function Get-OpenRemoteBaseKey {
    param (
        [Microsoft.Win32.RegistryHive]$RegistryHive,
        [string]$ComputerName
    )
    return [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $ComputerName)
}
