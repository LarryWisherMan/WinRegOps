function Export-RegistryKey {
    param (
        [string]$RegistryPath,   # The registry path to be exported
        [string]$ExportPath,     # The path where the backup .reg file will be saved
        [string]$ComputerName = $env:COMPUTERNAME    # The name of the computer (local or remote)
    )

    try {
        $exportCommand = "reg export `"$RegistryPath`" `"$ExportPath`" /y"

        # Execute the export command
        $exportResult = Invoke-Expression $exportCommand
        if ($LASTEXITCODE -eq 0) {
            return @{
                Success      = $true
                BackupPath   = $ExportPath
                Message      = "Registry key '$RegistryPath' successfully backed up to '$ExportPath'."
                ComputerName = $ComputerName
            }
        } else {
            return @{
                Success      = $false
                BackupPath   = $null
                Message      = "Failed to export registry key '$RegistryPath'."
                ComputerName = $ComputerName
            }
        }
    } catch {
        return @{
            Success      = $false
            BackupPath   = $null
            Message      = "Error during registry export for key '$RegistryPath'. $_"
            ComputerName = $ComputerName
        }
    }
}
