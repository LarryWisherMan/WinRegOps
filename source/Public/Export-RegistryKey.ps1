<#
.SYNOPSIS
Exports a registry key to a .reg file.

.DESCRIPTION
This function exports a registry key to a specified file path. It can be run on a local or remote computer. The function uses the 'reg export' command to perform the export operation and returns the success status.

.PARAMETER RegistryPath
The full path of the registry key to be exported.

.PARAMETER ExportPath
The file path where the exported .reg file will be saved.

.PARAMETER ComputerName
The name of the computer from which the registry key will be exported. Defaults to the local computer.

.EXAMPLE
Export-RegistryKey -RegistryPath 'HKCU\Software\MyApp' -ExportPath 'C:\Backups\MyApp.reg'

Exports the registry key 'HKCU\Software\MyApp' to 'C:\Backups\MyApp.reg'.

.OUTPUTS
System.Object

.NOTES
#>
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
