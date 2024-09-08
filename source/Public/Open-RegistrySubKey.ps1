<#
.SYNOPSIS
Opens a subkey under a specified registry key.

.DESCRIPTION
This function opens a subkey under a specified registry key. If the subkey does not exist, it returns $null.

.PARAMETER ParentKey
The parent registry key object.

.PARAMETER SubKeyName
The name of the subkey to open.

.EXAMPLE
$key = Open-RegistryKey -RegistryPath 'HKLM\Software'
Open-RegistrySubKey -ParentKey $key -SubKeyName 'MyApp'

Opens the subkey 'MyApp' under the registry key 'HKLM\Software'.

.OUTPUTS
Microsoft.Win32.RegistryKey

.NOTES
#>
function Open-RegistrySubKey
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Microsoft.Win32.RegistryKey]$ParentKey,

        [Parameter(Mandatory = $true)]
        [string]$SubKeyName
    )

    try
    {
        # Attempt to open the subkey from the parent registry key
        $subKey = $ParentKey.OpenSubKey($SubKeyName)

        # Return the opened subkey or $null if it doesn't exist
        return $subKey
    }
    catch
    {
        # Log the error and return $null in case of an exception
        Write-Error "Failed to open subkey '$SubKeyName'. Exception: $_"
        return $null
    }
}
