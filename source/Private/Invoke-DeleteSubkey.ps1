<#
.SYNOPSIS
    Deletes a specified subkey from the Windows registry.
.DESCRIPTION
    The `Invoke-DeleteSubKey` function deletes a subkey from the Windows registry.
    It provides flexibility to either pass a registry hive and path or an existing registry key object to delete the subkey.
    It supports deleting subkeys on both local and remote computers.

    This function is used internally by the `Remove-RegistrySubKey` cmdlet to delete a subkey from the Windows registry.
    It is not intended to be used directly by end users.

.PARAMETER ParentKey
    Specifies the parent registry key object from which to delete the subkey.

.PARAMETER SubKeyName
    Specifies the name of the subkey to delete.

.PARAMETER ThrowOnMissingSubKey

    Indicates whether the function should throw an error if the subkey to delete does not exist.
    If set to `$false`, no error will be thrown when attempting to delete a non-existent subkey. Defaults to `$true`.

.INPUTS
    Microsoft.Win32.RegistryKey

.OUTPUTS
    None

.EXAMPLE
    $parentKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SOFTWARE\MyApp', $true)
    Invoke-DeleteSubKey -ParentKey $parentKey -SubKeyName 'Settings'

    This command deletes the 'Settings' subkey under 'HKEY_LOCAL_MACHINE\SOFTWARE\MyApp' using the parent key object.

.NOTES
    This function uses the .NET `Microsoft.Win32.RegistryKey` class to interact with the Windows registry.
    It is recommended to run this function with appropriate permissions, as registry edits may require elevated privileges.
#>
function Invoke-DeleteSubKey
{
    param(
        [Microsoft.Win32.RegistryKey]$ParentKey,
        [string]$SubKeyName,
        [bool]$ThrowOnMissingSubKey = $true
    )

    if ($ParentKey -eq $null)
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
            $ParentKey.DeleteSubKey($SubKeyName, $true)
        }
        else
        {
            $ParentKey.DeleteSubKey($SubKeyName, $false)
        }
    }

    catch
    {
        throw $_
    }
}
