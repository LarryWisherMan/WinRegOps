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
function Open-RegistrySubKey {
    param (
        [Microsoft.Win32.RegistryKey]$ParentKey,
        [string]$SubKeyName
    )

    try {
        $subKey = $ParentKey.OpenSubKey($SubKeyName)
        if ($subKey -eq $null) {
            Write-Warning "The subkey '$SubKeyName' does not exist."
            return $null
        }
        return $subKey
    } catch {
        Write-Error "Error accessing subkey '$SubKeyName'. Error: $_"
        return $null
    }
}
