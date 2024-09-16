<#
.SYNOPSIS
    Retrieves a registry subkey from a given base key with various options for access control.

.DESCRIPTION
    The Get-RegistrySubKey function is a wrapper for the .NET `Microsoft.Win32.RegistryKey.OpenSubKey` method.
    It allows retrieving a subkey with different access control settings, such as writable, permission checks,
    or registry rights, depending on the parameter set.

    The function uses three parameter sets:
    - BooleanSet: Opens a subkey with or without writable access.
    - PermissionCheckSet: Opens a subkey with a specific permission check option.
    - RightsSet: Opens a subkey with a specific access control right (e.g., ReadKey, WriteKey, or FullControl).

.PARAMETER BaseKey
    The base registry key from which to open a subkey. This must be a valid `Microsoft.Win32.RegistryKey` object
    and is required in all parameter sets. It can be passed through the pipeline.

.PARAMETER Name
    The name of the subkey to open. This parameter is required for all parameter sets.

.PARAMETER Writable
    Specifies whether the subkey should be opened with writable access. This is only valid in the 'BooleanSet' parameter set.

.PARAMETER PermissionCheck
    Specifies the type of permission check to use when opening the subkey. Valid values include:
    - Default: The default permission check.
    - ReadSubTree: Allows read-only access.
    - ReadWriteSubTree: Allows both read and write access.
    This parameter is only valid in the 'PermissionCheckSet' parameter set.

.PARAMETER Rights
    Specifies the rights used to open the subkey. Valid values include:
    - ReadKey: Grants read access to the subkey.
    - WriteKey: Grants write access to the subkey.
    - FullControl: Grants full control (read and write) to the subkey.
    This parameter is only valid in the 'RightsSet' parameter set.

.INPUTS
    Microsoft.Win32.RegistryKey
        You can pipe a `RegistryKey` object to the function as the BaseKey.

.OUTPUTS
    Microsoft.Win32.RegistryKey
        The function returns the opened registry subkey if successful.

.EXAMPLE
    # Example 1: Open a subkey with writable access
    $baseKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey("Software")
    Get-RegistrySubKey -BaseKey $baseKey -Name "MyApp" -Writable $true

.Example
    # Example 2: Open a subkey with permission check (read-only access)
    $baseKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey("Software")
    Get-RegistrySubKey -BaseKey $baseKey -Name "MyApp" -PermissionCheck [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadSubTree

.Example
    # Example 3: Open a subkey with specific rights (read access)
    $baseKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey("Software")
    Get-RegistrySubKey -BaseKey $baseKey -Name "MyApp" -Rights [System.Security.AccessControl.RegistryRights]::ReadKey

.NOTES
    This function is designed to provide a PowerShell interface to interact with the .NET `RegistryKey` class,
    offering flexibility with different access control options.

.LINK
    https://learn.microsoft.com/en-us/dotnet/api/microsoft.win32.registrykey?view=net-8.0
#>
function Get-RegistrySubKey
{
    [Alias("Open-RegistrySubKey")]
    [CmdletBinding(DefaultParameterSetName = 'DefaultSet')]
    param (
        # Include 'BaseKey' in multiple sets and accept it from the pipeline
        [Parameter(Mandatory = $true, ParameterSetName = 'BooleanSet', ValueFromPipeline = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'PermissionCheckSet', ValueFromPipeline = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'RightsSet', ValueFromPipeline = $true)]
        [Microsoft.Win32.RegistryKey]$BaseKey,

        # 'Name' parameter belongs to all sets
        [Parameter(Mandatory = $true, ParameterSetName = 'BooleanSet')]
        [Parameter(Mandatory = $true, ParameterSetName = 'PermissionCheckSet')]
        [Parameter(Mandatory = $true, ParameterSetName = 'RightsSet')]
        [string]$Name,

        # 'writable' is only in the 'BooleanSet'
        [Parameter(Mandatory = $true, ParameterSetName = 'BooleanSet')]
        [ValidateSet([bool]$true, [bool]$false)]  # Choices for bool parameters
        [bool]$writable,

        # 'permissionCheck' is only in the 'PermissionCheckSet'
        [Parameter(Mandatory = $true, ParameterSetName = 'PermissionCheckSet')]
        [ValidateSet([Microsoft.Win32.RegistryKeyPermissionCheck]::Default,
            [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadSubTree,
            [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree)]
        [Microsoft.Win32.RegistryKeyPermissionCheck]$permissionCheck,

        # 'rights' is only in the 'RightsSet'
        [Parameter(Mandatory = $true, ParameterSetName = 'RightsSet')]
        [ValidateSet([System.Security.AccessControl.RegistryRights]::ReadKey,
            [System.Security.AccessControl.RegistryRights]::WriteKey,
            [System.Security.AccessControl.RegistryRights]::FullControl)]
        [System.Security.AccessControl.RegistryRights]$rights
    )

    process
    {
        try
        {
            switch ($PSCmdlet.ParameterSetName)
            {
                'BooleanSet'
                {
                    return $BaseKey.OpenSubKey($Name, $writable)
                }
                'PermissionCheckSet'
                {
                    return $BaseKey.OpenSubKey($Name, $permissionCheck)
                }
                'RightsSet'
                {
                    return $BaseKey.OpenSubKey($Name, $rights)
                }
                default
                {
                    throw "Unknown parameter set: $($PSCmdlet.ParameterSetName)"
                }
            }
        }
        catch [System.Security.SecurityException]
        {
            $errorMessage = "SecurityException: Requested registry access is not allowed. Please check your permissions."
            throw [System.Security.SecurityException] $errorMessage
        }
        catch
        {
            throw
        }
    }
}
