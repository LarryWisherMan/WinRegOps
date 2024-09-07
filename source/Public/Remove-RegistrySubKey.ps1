function Remove-RegistrySubKey {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
    param (
        [Parameter(Mandatory = $true)]
        [Microsoft.Win32.RegistryKey]$ParentKey,  # The parent registry key
        [string]$SubKeyName,                      # The subkey to be deleted
        [string]$ComputerName = $env:COMPUTERNAME # Default to local computer
    )

    try {
        # Ensure ShouldProcess is used for safety with -WhatIf and -Confirm support
        if ($PSCmdlet.ShouldProcess("Registry subkey '$SubKeyName' on $ComputerName", "Remove")) {
            $ParentKey.DeleteSubKeyTree($SubKeyName)
            Write-Verbose "Successfully removed registry subkey '$SubKeyName' on $ComputerName."
            return $true
        }
    } catch {
        Write-Error "Failed to remove the registry subkey '$SubKeyName' on $ComputerName. Error: $_"
        return $false
    }
}
