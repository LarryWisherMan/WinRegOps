function Get-RegistryValue {
    param (
        [Microsoft.Win32.RegistryKey]$Key,
        [string]$ValueName
    )

    try {
        # Retrieve the specified registry value
        $value = $Key.GetValue($ValueName, $null)
        if (-not $value) {
            Write-Verbose "$ValueName not found in the registry key."
        }
        return $value
    } catch {
        Write-Error "Failed to retrieve value '$ValueName'. Error: $_"
        return $null
    }
}
