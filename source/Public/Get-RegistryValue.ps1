<#
.SYNOPSIS
    Retrieves a value from a specified registry key, with support for default values and options.

.DESCRIPTION
    This function wraps the RegistryKey.GetValue method to retrieve a value from the Windows registry.
    You can supply a base registry key, the value name, an optional default value, and retrieval options.

.PARAMETER BaseKey
    The base registry key from which to retrieve the value. This should be an open RegistryKey object.

.PARAMETER ValueName
    The name of the registry value to retrieve. This is a required parameter.

.PARAMETER DefaultValue
    An optional default value to return if the specified name is not found in the registry.
    If not provided, the method will return $null if the value name does not exist.

.PARAMETER Options
    Optional retrieval options for the value. The available options are:
    - None: The default behavior.
    - DoNotExpandEnvironmentNames: Prevents the expansion of environment-variable strings.
    The default value for this parameter is [System.Registry.RegistryValueOptions]::None.

.EXAMPLE
    $baseKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SOFTWARE\MyApp")
    Get-RegistryValue -BaseKey $baseKey -ValueName "Setting1"

    Description:
    Retrieves the "Setting1" value from the "SOFTWARE\MyApp" registry key in the LocalMachine hive.

.EXAMPLE
    $baseKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SOFTWARE\MyApp")
    Get-RegistryValue -BaseKey $baseKey -ValueName "Setting1" -DefaultValue "DefaultValue"

    Description:
    Retrieves the "Setting1" value from the "SOFTWARE\MyApp" registry key. If the value does not exist, it returns "DefaultValue".

.EXAMPLE
    $baseKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SOFTWARE\MyApp")
    Get-RegistryValue -BaseKey $baseKey -ValueName "Setting1" -DefaultValue "DefaultValue" -Options [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames

    Description:
    Retrieves the "Setting1" value with the option to prevent expanding environment-variable strings. If the value does not exist, it returns "DefaultValue".

.NOTES
    This function wraps around the .NET Framework's RegistryKey.GetValue method to make it easier to retrieve registry values in PowerShell.

#>

function Get-RegistryValue
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [Microsoft.Win32.RegistryKey]$BaseKey,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$ValueName,

        [Parameter(Mandatory = $false, Position = 2)]
        [Object]$DefaultValue = $null,

        [Parameter(Mandatory = $false, Position = 3)]
        [Microsoft.Win32.RegistryOptions]$Options = [Microsoft.Win32.RegistryOptions]::None
    )

    try
    {
        # Retrieve the registry value based on the provided options and default value
        if ($Options -ne [Microsoft.Win32.RegistryOptions]::None)
        {
            return $BaseKey.GetValue($ValueName, $DefaultValue, $Options)
        }
        elseif ($DefaultValue)
        {
            return $BaseKey.GetValue($ValueName, $DefaultValue)
        }
        else
        {
            return $BaseKey.GetValue($ValueName)
        }
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
