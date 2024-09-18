<#
.SYNOPSIS
    Creates a custom object representing the values of a registry key or subkey.

.DESCRIPTION
    The New-RegistryKeyValuesObject function retrieves all the values of a specified registry key or subkey and returns a custom object containing the registry path, backup date, user, computer name, and the key's values.

    This function is flexible, allowing you to specify a subkey within the registry key, or work with the root key itself. Each value is stored along with its data type.

.PARAMETER RegistryKey
    The base registry key to be queried. This parameter is mandatory and must be a valid `Microsoft.Win32.RegistryKey` object.

.PARAMETER SubKeyName
    The name of the optional subkey within the `RegistryKey`. If provided, the function will operate on this subkey. If not provided, it will operate on the root registry key.

.PARAMETER User
    The username of the individual performing the backup. Defaults to the current user's name from `$env:USERNAME`.

.PARAMETER ComputerName
    The name of the computer where the registry key resides. Defaults to the current computer name from `$env:COMPUTERNAME`.

.OUTPUTS
    PSCustomObject
        Returns a custom object with the following properties:
        - RegistryPath: The full path of the registry key or subkey.
        - BackupDate: The date and time of the backup.
        - ByUser: The username of the individual performing the backup.
        - ComputerName: The name of the computer.
        - Values: A dictionary of all the values within the registry key, where each entry contains:
            - Value: The data stored in the registry key value.
            - Type: The data type of the registry value (e.g., String, DWord, Binary).

.EXAMPLE
    # Example 1: Export values from the root registry key
    $remoteRegistry = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, "RemotePC")
    $registryKey = $remoteRegistry.OpenSubKey("SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList")
    $registryData = New-RegistryKeyValuesObject -RegistryKey $registryKey

    This example opens the `ProfileList` key on a remote computer and exports the values to a custom object.

.EXAMPLE
    # Example 2: Export values from a specific subkey
    $remoteRegistry = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, "RemotePC")
    $registryKey = $remoteRegistry.OpenSubKey("SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList")
    $registryData = New-RegistryKeyValuesObject -RegistryKey $registryKey -SubKeyName "S-1-5-21-12345"

    This example exports the values from a specific subkey (`S-1-5-21-12345`) within the `ProfileList` key on a remote computer.

.NOTES
    - The function is useful for backing up registry data or auditing changes within a registry key.
    - Ensure that you have appropriate permissions to access the registry keys.

.LINK
    https://learn.microsoft.com/en-us/dotnet/api/microsoft.win32.registrykey?view=net-8.0
#>

function New-RegistryKeyValuesObject
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'No state changes are made in this function.')]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Microsoft.Win32.RegistryKey]$RegistryKey, # Generic registry key

        [string]$SubKeyName, # Optional subkey name within the registry key

        [string]$User = $env:USERNAME,

        [string]$ComputerName = $env:COMPUTERNAME
    )

    # Automatically set RegistryPath to the name of the registry key or subkey if provided
    if ($SubKeyName)
    {
        $subKey = Get-RegistrySubKey -BaseKey $RegistryKey -Name $SubKeyName -writable $false
        $RegistryPath = $subKey.Name
        $selectedKey = $subKey
    }
    else
    {
        $RegistryPath = $RegistryKey.Name
        $selectedKey = $RegistryKey
    }

    # Create the registry data object
    $registryData = [PSCustomObject]@{
        RegistryPath = $RegistryPath
        BackupDate   = Get-Date
        ByUser       = $User
        ComputerName = $ComputerName
        Values       = @{}
    }

    # Collect all value names and types from the subkey or root key
    foreach ($valueName in (Get-RegistryValueNames -baseKey $selectedKey))
    {
        $value = Get-RegistryValue -BaseKey $selectedKey -ValueName $valueName
        $valueType = (Get-RegistryValueKind -BaseKey $selectedKey -ValueName $valueName).tostring()
        $registryData.Values[$valueName] = @{
            Value = $value
            Type  = $valueType
        }
    }

    return $registryData
}

