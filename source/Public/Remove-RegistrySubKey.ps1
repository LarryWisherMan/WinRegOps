<#
.SYNOPSIS
Removes a subkey from a registry key.

.DESCRIPTION
This function deletes a subkey from a specified parent registry key. It supports the -WhatIf and -Confirm parameters for safety.

.PARAMETER ParentKey
The parent registry key object.

.PARAMETER SubKeyName
The name of the subkey to be deleted.

.PARAMETER ComputerName
The name of the computer where the registry subkey is located. Defaults to the local computer.

.EXAMPLE
$key = Open-RegistryKey -RegistryPath 'HKLM\Software'
Remove-RegistrySubKey -ParentKey $key -SubKeyName 'MyApp'

Deletes the subkey 'MyApp' under the registry key 'HKLM\Software' on the local computer.

.EXAMPLE
$key = Open-RegistryKey -RegistryPath 'HKLM\Software'
Remove-RegistrySubKey -ParentKey $key -SubKeyName 'MyApp' -WhatIf

Shows what would happen if the subkey 'MyApp' were deleted, without actually performing the deletion.

.OUTPUTS
System.Boolean

.NOTES

#>
function Remove-RegistrySubKey
{
    [outputType([system.Boolean])]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory = $true)]
        [Microsoft.Win32.RegistryKey]$ParentKey, # The parent registry key
        [string]$SubKeyName, # The subkey to be deleted
        [string]$ComputerName = $env:COMPUTERNAME # Default to local computer
    )

    try
    {
        # Ensure ShouldProcess is used for safety with -WhatIf and -Confirm support
        if ($PSCmdlet.ShouldProcess("Registry subkey '$SubKeyName' on $ComputerName", "Remove"))
        {
            # Proceed with deletion
            $ParentKey.DeleteSubKeyTree($SubKeyName)
            Write-Verbose "Successfully removed registry subkey '$SubKeyName' on $ComputerName."
            return $true
        }
        else
        {
            # ShouldProcess returned false, so nothing is done
            Write-Verbose "Operation to remove registry subkey '$SubKeyName' on $ComputerName was skipped."
            return $false
        }

    }
    catch
    {
        Write-Error "Failed to remove the registry subkey '$SubKeyName' on $ComputerName. Error: $_"
        return $false
    }
}
