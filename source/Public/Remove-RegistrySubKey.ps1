<#
.SYNOPSIS
Removes a specified subkey from the Windows registry.

.DESCRIPTION
The `Remove-RegistrySubKey` cmdlet removes a subkey from the Windows registry.
It provides flexibility to either pass a registry hive and path or an existing registry key object to delete the subkey.
It supports deleting subkeys on both local and remote computers.

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
Specifies an existing registry key object from which to delete the subkey. This parameter is part of the 'ByKey' parameter set.

.PARAMETER SubKeyName
Specifies the name of the subkey to delete. This parameter is part of the 'ByKey' parameter set.

.PARAMETER ThrowOnMissingSubKey
Indicates whether the cmdlet should throw an error if the subkey to delete does not exist.
If set to `$false`, no error will be thrown when attempting to delete a non-existent subkey. Defaults to `$true`.

.EXAMPLE
Remove-RegistrySubKey -RegistryHive LocalMachine -RegistryPath 'SOFTWARE\MyApp\Settings'

This command deletes the 'Settings' subkey under 'HKEY_LOCAL_MACHINE\SOFTWARE\MyApp' on the local machine.

.EXAMPLE
$parentKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SOFTWARE\MyApp', $true)
Remove-RegistrySubKey -ParentKey $parentKey -SubKeyName 'Settings'

This command deletes the 'Settings' subkey under 'HKEY_LOCAL_MACHINE\SOFTWARE\MyApp' using the parent key object.

.EXAMPLE
Remove-RegistrySubKey -RegistryHive LocalMachine -RegistryPath 'SOFTWARE\MyApp\Settings' -ComputerName 'RemotePC'

This command deletes the 'Settings' subkey under 'HKEY_LOCAL_MACHINE\SOFTWARE\MyApp' on a remote computer named 'RemotePC'.

.NOTES
This function uses the .NET `Microsoft.Win32.RegistryKey` class to interact with the Windows registry.
It is recommended to run this cmdlet with appropriate permissions, as registry edits may require elevated privileges.

#>
function Remove-RegistrySubKey
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High', DefaultParameterSetName = 'ByHive')]
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
        [string]$SubKeyName,
        [Parameter(ParameterSetName = 'ByHive')]
        [Parameter(ParameterSetName = 'ByKey')]
        [bool]$ThrowOnMissingSubKey = $true

    )

    begin
    {
        if ($PSCmdlet.ParameterSetName -eq "ByHive")
        {
            $params = @{
                RegistryPath     = $RegistryPath
                RegistryHive     = $RegistryHive
                ComputerName     = $ComputerName
                ParameterSetName = $PSCmdlet.ParameterSetName
            }
        }
        else
        {
            $params = @{
                ParentKey        = $ParentKey
                SubKeyName       = $SubKeyName
                ParameterSetName = $PSCmdlet.ParameterSetName
            }
        }

        $operationDetails = Get-RegistrySubKeyOperation @params

        $ParentKey = $operationDetails.ParentKey
        $subKeyName = $operationDetails.SubKeyName

        if ([string]::IsNullOrEmpty($subKeyName))
        {
            throw [System.ArgumentNullException]::new("SubKeyName cannot be null or empty.")
        }
    }


    process
    {
        if ($PSCmdlet.ShouldProcess("$($ParentKey.Name)\$subKeyName", "Removing registry subkey using DeleteSubKey"))
        {
            # Use DeleteSubKey method
            try
            {
                Invoke-DeleteSubKey -ParentKey $ParentKey -SubKeyName $subKeyName -ThrowOnMissingSubKey $ThrowOnMissingSubKey
            }
            catch
            {
                throw $_
            }
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
