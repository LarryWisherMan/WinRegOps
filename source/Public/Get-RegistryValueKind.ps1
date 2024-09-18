<#
.SYNOPSIS
    Retrieves the value kind (type) of a specified registry key value.

.DESCRIPTION
    This function wraps the RegistryKey.GetValueKind method to retrieve the type (kind) of a registry value.
    You can supply a base registry key and the value name. It returns the type of the value (e.g., String, DWord, Binary).

.PARAMETER BaseKey
    The base registry key from which to retrieve the value kind. This should be an open RegistryKey object.

.PARAMETER ValueName
    The name of the registry value for which to retrieve the kind. This is a required parameter.

.OUTPUTS
    Microsoft.Win32.RegistryValueKind
        The type of the value (e.g., String, DWord, Binary).

.EXAMPLE
    $baseKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SOFTWARE\MyApp")
    Get-RegistryValueKind -BaseKey $baseKey -ValueName "Setting1"

    Description:
    Retrieves the kind (type) of the "Setting1" value from the "SOFTWARE\MyApp" registry key.

.NOTES
    This function wraps around the .NET Framework's RegistryKey.GetValueKind method to make it easier to retrieve registry value types in PowerShell.
#>

function Get-RegistryValueKind
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [Microsoft.Win32.RegistryKey]$BaseKey,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$ValueName
    )

    try
    {
        # Retrieve the kind (type) of the registry value
        return $BaseKey.GetValueKind($ValueName)
    }
    catch [System.Security.SecurityException]
    {
        $errorMessage = "Access to the registry key is denied."
        throw [System.Security.SecurityException] $errorMessage
    }
    catch
    {
        throw $_
    }
}
