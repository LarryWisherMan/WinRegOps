<#
.SYNOPSIS
Retrieves a value from a specified registry key.

.DESCRIPTION
This function retrieves a specific value from a registry key. It returns the value if found, or $null if the value does not exist.

.PARAMETER Key
The registry key object from which the value will be retrieved.

.PARAMETER ValueName
The name of the value to retrieve from the registry key.

.EXAMPLE
$key = Open-RegistryKey -RegistryPath 'HKLM\Software\MyApp'
Get-RegistryValue -Key $key -ValueName 'Setting'

Retrieves the value 'Setting' from the registry key 'HKLM\Software\MyApp'.

.OUTPUTS
System.Object

.NOTES
#>

function Get-RegistryValue
{
    param (
        [Microsoft.Win32.RegistryKey]$Key,
        [string]$ValueName
    )

    try
    {
        # Retrieve the specified registry value
        $value = $Key.GetValue($ValueName, $null)
        return $value
    }
    catch
    {
        Write-Error "Failed to retrieve value '$ValueName'. Error: $_"
        return $null
    }
}
