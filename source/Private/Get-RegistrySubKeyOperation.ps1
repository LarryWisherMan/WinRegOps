<#
.SYNOPSIS
Prepares the registry subkey operation by opening the relevant registry key based on the parameter set.

.DESCRIPTION
This function prepares the environment for removing a registry subkey. It opens the correct registry key either by
registry hive and path or by an existing registry key object, and returns the parent key and subkey name for further processing.

.PARAMETER RegistryPath
Specifies the path to the registry key to open. This is used only when the 'ByHive' parameter set is selected.

.PARAMETER RegistryHive
Specifies the registry hive where the key resides. This is used only when the 'ByHive' parameter set is selected.

.PARAMETER ComputerName
Specifies the name of the computer on which to perform the registry operation. This is used only when the 'ByHive' parameter set is selected.
Defaults to the local machine if not specified.

.PARAMETER ParentKey
Specifies an existing registry key object from which to delete the subkey. This is used only when the 'ByKey' parameter set is selected.

.PARAMETER SubKeyName
Specifies the name of the subkey to delete.

.PARAMETER ParameterSetName
Specifies which parameter set is being used. It should be either 'ByHive' or 'ByKey'.

.Outputs
System.Collections.Hashtable

.EXAMPLE
$details = Get-RegistrySubKeyOperation -RegistryPath 'SOFTWARE\MyApp' -RegistryHive LocalMachine -ComputerName 'RemotePC' -ParameterSetName 'ByHive'

This example prepares a registry operation on a remote computer by opening the 'SOFTWARE\MyApp' subkey in HKEY_LOCAL_MACHINE.

.EXAMPLE
$parentKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SOFTWARE\MyApp', $true)
$details = Get-RegistrySubKeyOperation -ParentKey $parentKey -SubKeyName 'Settings' -ParameterSetName 'ByKey'

This example prepares a registry operation by passing an already opened parent key and the subkey 'Settings'.
#>
function Get-RegistrySubKeyOperation
{
    param (
        [string]$RegistryPath,
        [Microsoft.Win32.RegistryHive]$RegistryHive,
        [string]$ComputerName,
        [Microsoft.Win32.RegistryKey]$ParentKey,
        [string]$SubKeyName,
        [string]$ParameterSetName
    )

    if ($ParameterSetName -eq 'ByHive')
    {
        # Split path and get subkey name
        $parentPath = Split-Path -Path $RegistryPath -Parent
        $subKeyName = Split-Path -Path $RegistryPath -Leaf

        # Open the registry key
        try
        {
            $ParentKey = Open-RegistryKey -RegistryPath $parentPath -RegistryHive $RegistryHive -ComputerName $ComputerName -Writable $true
        }
        catch
        {
            throw "Failed to open registry key: $($RegistryHive)\$parentPath. $_"
        }

        return @{ ParentKey = $ParentKey; SubKeyName = $subKeyName }
    }
    elseif ($ParameterSetName -eq 'ByKey')
    {
        if ($null -eq $ParentKey)
        {
            throw [System.ArgumentNullException]::new("ParentKey cannot be null.")
        }
        return @{ ParentKey = $ParentKey; SubKeyName = $SubKeyName }
    }

    throw [System.ArgumentException]::new("Invalid parameter set.")
}
