<#
.SYNOPSIS
Recursively removes a specified subkey and all of its subkeys from the Windows registry.

.DESCRIPTION
The `Remove-RegistrySubKeyTree` cmdlet deletes a registry subkey and all of its child subkeys (if any) from the Windows registry.
This cmdlet provides flexibility to either specify a registry hive and path, or pass an existing registry key object to delete the subkey tree.
It supports deleting registry subkeys on both local and remote computers.

.PARAMETER RegistryHive
Specifies the registry hive where the key resides. This parameter is part of the 'ByHive' parameter set.
Accepted values are:
- ClassesRoot
- CurrentUser
- LocalMachine
- Users
- PerformanceData
- CurrentConfig
- DynData

.PARAMETER RegistryPath
Specifies the path to the registry key that contains the subkey to delete. This parameter is part of the 'ByHive' parameter set.

.PARAMETER ComputerName
Specifies the name of the computer on which to perform the registry operation. Defaults to the local machine if not specified. This parameter is part of the 'ByHive' parameter set.

.PARAMETER ParentKey
Specifies an existing registry key object from which to delete the subkey tree. This parameter is part of the 'ByKey' parameter set.

.PARAMETER SubKeyName
Specifies the name of the subkey to delete, including all of its child subkeys. This parameter is part of the 'ByKey' parameter set.

.EXAMPLE
Remove-RegistrySubKeyTree -RegistryHive LocalMachine -RegistryPath 'SOFTWARE\MyApp\Settings'

This command deletes the 'Settings' subkey and all its child subkeys under 'HKEY_LOCAL_MACHINE\SOFTWARE\MyApp' on the local machine.

.EXAMPLE
$parentKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SOFTWARE\MyApp', $true)
Remove-RegistrySubKeyTree -ParentKey $parentKey -SubKeyName 'Settings'

This command deletes the 'Settings' subkey and all its child subkeys under 'HKEY_LOCAL_MACHINE\SOFTWARE\MyApp' using the parent key object.

.EXAMPLE
Remove-RegistrySubKeyTree -RegistryHive LocalMachine -RegistryPath 'SOFTWARE\MyApp\Settings' -ComputerName 'RemotePC'

This command deletes the 'Settings' subkey and all its child subkeys under 'HKEY_LOCAL_MACHINE\SOFTWARE\MyApp' on a remote computer named 'RemotePC'.

.NOTES
This function uses the .NET `Microsoft.Win32.RegistryKey` class to interact with the Windows registry.
Registry operations can be sensitive, and it is recommended to run this cmdlet with appropriate permissions (e.g., as an Administrator) to avoid access issues.

#>
function Remove-RegistrySubKeyTree
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High", DefaultParameterSetName = 'ByHive')]
    param (
        # Parameter Set: ByHive
        [Parameter(Mandatory, ParameterSetName = 'ByHive')]
        [ValidateSet(
            [Microsoft.Win32.RegistryHive]::ClassesRoot,
            [Microsoft.Win32.RegistryHive]::CurrentUser,
            [Microsoft.Win32.RegistryHive]::LocalMachine,
            [Microsoft.Win32.RegistryHive]::Users,
            [Microsoft.Win32.RegistryHive]::PerformanceData,
            [Microsoft.Win32.RegistryHive]::CurrentConfig,
            [Microsoft.Win32.RegistryHive]::DynData
        )
        ]
        [Microsoft.Win32.RegistryHive]$RegistryHive,
        [Parameter(Mandatory, ParameterSetName = 'ByHive')]
        [string]$RegistryPath,
        [Parameter(ParameterSetName = 'ByHive')]
        [string]$ComputerName = $env:COMPUTERNAME,

        # Parameter Set: ByKey
        [Parameter(Mandatory, ParameterSetName = 'ByKey')]
        [Microsoft.Win32.RegistryKey]$ParentKey,
        [Parameter(Mandatory, ParameterSetName = 'ByKey')]
        [string]$SubKeyName
    )

    begin
    {
        # Determine which base key to use
        if ($PSCmdlet.ParameterSetName -eq 'ByHive')
        {
            # Split the RegistryPath into parent path and subkey name
            $parentPath = Split-Path -Path $RegistryPath -Parent
            $subKeyName = Split-Path -Path $RegistryPath -Leaf

            # Open the parent key using Open-RegistryKey
            try
            {
                $ParentKey = Open-RegistryKey -RegistryPath $parentPath -RegistryHive $RegistryHive -ComputerName $ComputerName -Writable $true
            }
            catch
            {
                throw $_
            }

            if ($null -eq $ParentKey)
            {
                throw [System.ObjectDisposedException]::new("Failed to open registry key: $($RegistryHive)\$parentPath")
            }
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'ByKey')
        {
            if ($null -eq $ParentKey)
            {
                throw [System.ArgumentNullException]::new("ParentKey cannot be null.")
            }
            $subKeyName = $SubKeyName
        }

        # Ensure that subKeyName is not null or empty
        if ([string]::IsNullOrEmpty($subKeyName))
        {
            throw [System.ArgumentNullException]::new("SubKeyName cannot be null or empty.")
        }
    }

    process
    {
        if ($PSCmdlet.ShouldProcess("$($ParentKey.Name)\$subKeyName", "Removing registry subkey tree"))
        {
            # Call Invoke-DeleteSubKeyTree to handle the deletion
            Invoke-DeleteSubKeyTree -ParentKey $ParentKey -SubKeyName $subKeyName -ThrowOnMissingSubKey $true
            Write-Verbose "SubKey '$subKeyName' and its child subkeys deleted using DeleteSubKeyTree."
        }
    }

    end
    {
        # If we opened the ParentKey internally, dispose of it
        if ($PSCmdlet.ParameterSetName -eq 'ByHive' -and $null -ne $ParentKey)
        {
            $ParentKey.Dispose()
        }
    }
}
