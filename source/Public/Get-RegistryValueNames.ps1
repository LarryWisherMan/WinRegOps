<#
.SYNOPSIS
    Retrieves all the value names of a specified registry key.

.DESCRIPTION
    This function wraps the RegistryKey.GetValueNames method to retrieve all the value names of a registry key.
    You can supply a base registry key, and the function will return an array of the value names present in the registry key.

.PARAMETER BaseKey
    The base registry key from which to retrieve the value names. This should be an open RegistryKey object.

.OUTPUTS
    String[]
        An array of strings representing the names of all the values stored in the registry key.

.EXAMPLE
    $baseKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SOFTWARE\MyApp")
    Get-RegistryValueNames -BaseKey $baseKey

    Description:
    Retrieves all the value names from the "SOFTWARE\MyApp" registry key.

.NOTES
    This function wraps around the .NET Framework's RegistryKey.GetValueNames method to make it easier to retrieve value names in PowerShell.
#>

function Get-RegistryValueNames
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'The function name is appropriate.')]

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [Microsoft.Win32.RegistryKey]$BaseKey
    )

    try
    {
        # Retrieve all the value names in the registry key
        return $BaseKey.GetValueNames()
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

