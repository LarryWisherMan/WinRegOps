<#
.SYNOPSIS
Opens a registry key on a local or remote computer.

.DESCRIPTION
This function opens a registry key on a local or remote computer. It returns the registry key object if successful, or $null if the key does not exist or access is denied.

.PARAMETER RegistryPath
The full path of the registry key to be opened.

.PARAMETER RegistryHive
The registry hive to open (e.g., HKEY_LOCAL_MACHINE, HKEY_CURRENT_USER). Defaults to HKEY_LOCAL_MACHINE.

.PARAMETER ComputerName
The name of the computer where the registry key is located. Defaults to the local computer.

.PARAMETER Writable
Specifies whether the registry key should be opened with writable access. Defaults to $true.

.EXAMPLE
Open-RegistryKey -RegistryPath 'HKLM\Software\MyApp'

Opens the registry key 'HKLM\Software\MyApp' on the local computer.

.EXAMPLE
Open-RegistryKey -RegistryPath 'Software\MyApp' -RegistryHive 'HKEY_CURRENT_USER' -ComputerName 'RemotePC'

Opens the registry key 'Software\MyApp' under HKEY_CURRENT_USER on the remote computer 'RemotePC'.

.OUTPUTS
Microsoft.Win32.RegistryKey

.NOTES
This function uses helper functions Get-OpenBaseKey and Get-OpenRemoteBaseKey to abstract the static calls for opening registry keys locally or remotely.
#>

function Open-RegistryKey
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RegistryPath,

        [Parameter(Mandatory = $false)]
        [Microsoft.Win32.RegistryHive]$RegistryHive = [Microsoft.Win32.RegistryHive]::LocalMachine,

        [Parameter(Mandatory = $false)]
        [string]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false)]
        [bool]$Writable = $true
    )

    try
    {
        # Determine if the operation is local or remote
        $isLocal = $ComputerName -eq $env:COMPUTERNAME
        $regKey = if ($isLocal)
        {
            Get-OpenBaseKey -RegistryHive $RegistryHive
        }
        else
        {
            Get-OpenRemoteBaseKey -RegistryHive $RegistryHive -ComputerName $ComputerName
        }
    }
    catch [System.Security.SecurityException]
    {
        $customError = "Access denied to registry hive '$RegistryHive' on '$ComputerName'. Ensure you have sufficient permissions."
        throw [System.Security.SecurityException] $customError
    }
    catch
    {
        Write-Error "Failed to open registry hive '$RegistryHive' on '$ComputerName'. Error: $_"
        return $null
    }

    try
    {
        # Open the subkey using Open-RegistrySubKey (alias for Get-RegistrySubKey)
        $openedKey = Open-RegistrySubKey -BaseKey $regKey -Name $RegistryPath -Writable $Writable

        if ($openedKey)
        {
            Write-Verbose "Successfully opened registry key at path '$RegistryPath' on '$ComputerName'."
            return $openedKey
        }
        else
        {
            Write-Warning "Registry key at path '$RegistryPath' not found on '$ComputerName'."
            return $null
        }
    }

    catch [System.Security.SecurityException]
    {
        $customError = "Access denied to registry SubKey '$RegistryPath' on '$ComputerName'. Ensure you have sufficient permissions."
        throw [System.Security.SecurityException] $customError
    }

    catch
    {
        Write-Error "Failed to open registry key at path '$RegistryPath' on '$ComputerName'. Error: $_"
        return $null
    }
}
