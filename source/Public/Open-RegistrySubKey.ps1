function Open-RegistrySubKey {
    param (
        [Microsoft.Win32.RegistryKey]$ParentKey,
        [string]$SubKeyName
    )

    try {
        $subKey = $ParentKey.OpenSubKey($SubKeyName)
        if ($subKey -eq $null) {
            Write-Warning "The subkey '$SubKeyName' does not exist."
            return $null
        }
        return $subKey
    } catch {
        Write-Error "Error accessing subkey '$SubKeyName'. Error: $_"
        return $null
    }
}
