function Open-RegistryKey {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RegistryPath,

        [Parameter(Mandatory = $false)]
        [Microsoft.Win32.RegistryHive]$RegistryHive = [Microsoft.Win32.RegistryHive]::LocalMachine,

        [Parameter(Mandatory = $false)]
        [string]$ComputerName = $env:COMPUTERNAME
    )

    try {
        # Determine if local or remote
        $isLocal = $ComputerName -eq $env:COMPUTERNAME
        $regKey = if ($isLocal) {
            [Microsoft.Win32.RegistryKey]::OpenBaseKey($RegistryHive, [Microsoft.Win32.RegistryView]::Default)
        } else {
            [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $ComputerName)
        }

        # Open the subkey
        $openedKey = $regKey.OpenSubKey($RegistryPath, $true)

        if ($openedKey) {
            Write-Verbose "Successfully opened registry key at path '$RegistryPath' on '$ComputerName'."
            return $openedKey
        } else {
            Write-Warning "Registry key at path '$RegistryPath' not found on '$ComputerName'."
            return $null
        }
    } catch [System.Security.SecurityException] {
        Write-Error "Access denied to registry key '$RegistryPath' on '$ComputerName'. Ensure you have sufficient permissions."
        return $null
    } catch {
        Write-Error "Failed to open registry key at path '$RegistryPath' on '$ComputerName'. Error: $_"
        return $null
    }
}
