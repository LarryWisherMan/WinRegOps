<#
.SYNOPSIS
Deletes a registry subkey and all of its child subkeys from the specified parent key.

.DESCRIPTION
The `Invoke-DeleteSubKeyTree` function deletes a specified subkey and all of its child subkeys from a provided registry key. It allows control over whether to throw an error if the subkey is missing.

.PARAMETER ParentKey
The parent registry key from which the subkey tree will be deleted. This parameter cannot be null.

.PARAMETER SubKeyName
The name of the subkey to delete, including all of its child subkeys. This parameter cannot be null or empty.

.PARAMETER ThrowOnMissingSubKey
Specifies whether an exception should be thrown if the subkey does not exist. Defaults to `$true`.

.EXAMPLE
$parentKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SOFTWARE\MyApp', $true)
Invoke-DeleteSubKeyTree -ParentKey $parentKey -SubKeyName 'Settings'

This command deletes the 'Settings' subkey and all its child subkeys under 'HKEY_LOCAL_MACHINE\SOFTWARE\MyApp'.

.EXAMPLE
$parentKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('SOFTWARE\MyApp', $true)
Invoke-DeleteSubKeyTree -ParentKey $parentKey -SubKeyName 'TempSettings' -ThrowOnMissingSubKey $false

This command deletes the 'TempSettings' subkey and all its child subkeys under 'HKEY_CURRENT_USER\SOFTWARE\MyApp', and does not throw an exception if the subkey does not exist.

.NOTES
This function uses the .NET `Microsoft.Win32.RegistryKey` class to interact with the Windows registry. Ensure you have appropriate permissions to perform registry modifications.

#>

Function Invoke-DeleteSubKeyTree
{

    param(
        [Microsoft.Win32.RegistryKey]$ParentKey,
        [string]$SubKeyName,
        [bool]$ThrowOnMissingSubKey = $true
    )

    if ($null -eq $ParentKey)
    {
        throw [System.ArgumentNullException]::new("ParentKey cannot be null.")
    }

    if ([string]::IsNullOrEmpty($SubKeyName))
    {
        throw [System.ArgumentNullException]::new("SubKeyName cannot be null or empty.")
    }

    try
    {
        if ($ThrowOnMissingSubKey)
        {
            $ParentKey.DeleteSubKeyTree($SubKeyName)
        }
        else
        {
            $ParentKey.DeleteSubKeyTree($SubKeyName, $false)
        }
    }
    catch
    {
        throw $_
    }

}
