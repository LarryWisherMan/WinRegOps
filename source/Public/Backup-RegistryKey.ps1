<#
.SYNOPSIS
Backs up a registry key from a specified computer to a backup file.

.DESCRIPTION
This function allows you to back up a registry key from a local or remote computer. It exports the registry key to a .reg file and saves it in the specified backup directory. It includes error handling for permission issues and remote access failures.

.PARAMETER ComputerName
The name of the computer from which the registry key will be backed up. Defaults to the local computer.

.PARAMETER RegistryPath
The full path of the registry key to be backed up.

.PARAMETER BackupDirectory
The directory where the backup file will be saved. Defaults to "C:\LHStuff\UserProfileTools\RegProfBackup".

.EXAMPLE
Backup-RegistryKey -RegistryPath 'HKLM\Software\MyApp' -BackupDirectory 'C:\Backups'

Backs up the registry key 'HKLM\Software\MyApp' on the local computer to the 'C:\Backups' directory.

.EXAMPLE
Backup-RegistryKey -ComputerName 'RemotePC' -RegistryPath 'HKLM\Software\MyApp'

Backs up the registry key 'HKLM\Software\MyApp' from the remote computer 'RemotePC' to the default backup directory.

.OUTPUTS
System.Object

.NOTES
#>

function Backup-RegistryKey
{
    [CmdletBinding()]
    param (
        [string]$ComputerName = $env:COMPUTERNAME,
        [Parameter(Mandatory = $true)]
        [string]$RegistryPath, # Now dynamic, can back up any registry path
        [string]$BackupDirectory = "C:\LHStuff\UserProfileTools\RegProfBackup"
    )

    # Determine if the operation is local or remote
    $isLocal = $ComputerName -eq $env:COMPUTERNAME

    # Generate the appropriate backup directory path (local or UNC)
    $backupDirectoryPath = Get-DirectoryPath -BasePath $BackupDirectory -ComputerName $ComputerName -IsLocal $isLocal

    # Ensure the backup directory exists locally or remotely
    Test-DirectoryExists -Directory $backupDirectoryPath

    # Generate the backup file path with timestamp
    $backupPath = Get-BackupFilePath -BackupDirectory $backupDirectoryPath

    # Get the full definition of Export-RegistryKey as a script block
    $exportRegistryFunction = Get-FunctionScriptBlock -FunctionName 'Export-RegistryKey'

    $scriptBlock = {
        param ($regExportPath, $registryPath, $exportFunction)

        # Load the Export-RegistryKey function
        Invoke-Expression $exportFunction

        # Export the registry key
        return Export-RegistryKey -RegistryPath $registryPath -BackupPath $regExportPath
    }

    try
    {
        if ($isLocal)
        {
            # Local backup
            $backupResult = Export-RegistryKey -RegistryPath $RegistryPath -BackupPath $backupPath
        }
        else
        {
            # Remote backup using Invoke-Command
            $backupResult = Invoke-Command -ComputerName $ComputerName -ScriptBlock $scriptBlock `
                -ArgumentList $backupPath, $RegistryPath, $exportRegistryFunction
        }

        # Return the result of the backup
        if ($backupResult.Success)
        {
            return @{
                Success      = $true
                BackupPath   = $backupPath
                Message      = "Registry key backed up successfully."
                ComputerName = $ComputerName
            }
        }
        else
        {
            Write-Error $backupResult.Message
            return @{
                Success      = $false
                BackupPath   = $null
                Message      = $backupResult.Message
                ComputerName = $ComputerName
            }
        }
    }
    catch
    {
        # Handle exceptions and return failure
        Write-Error "Failed to back up the registry key '$RegistryPath' on $ComputerName. Error: $_"
        return @{
            Success      = $false
            BackupPath   = $null
            Message      = "Failed to back up the registry key '$RegistryPath'. Error: $_"
            ComputerName = $ComputerName
        }
    }
}
