function Backup-RegistryKey {
    param (
        [string]$ComputerName = $env:COMPUTERNAME,
        [string]$RegistryPath,  # Now dynamic, can back up any registry path
        [string]$BackupDirectory = "C:\LHStuff\UserProfileTools\RegProfBackup"
    )

    # Determine if the operation is local or remote
    $isLocal = $ComputerName -eq $env:COMPUTERNAME

    # Generate the appropriate backup directory path (local or UNC)
    $backupDirectoryPath = Get-DirectoryPath -BasePath $BackupDirectory -ComputerName $ComputerName -IsLocal $isLocal

    # Ensure the backup directory exists locally or remotely
    Test-DirectoryExists -Directory $backupDirectoryPath

    # Generate the backup file path with timestamp
    $backupPath = Get-BackupFilePath -BackupDirectory $BackupDirectory

    # Get the full definition of Export-RegistryKey as a script block
    $exportRegistryFunction = Get-FunctionScriptBlock -FunctionName 'Export-RegistryKey'

    $scriptBlock = {
        param ($regExportPath, $registryPath, $exportFunction)

        # Load the Export-RegistryKey function
        Invoke-Expression $exportFunction

        # Export the registry key
        return Export-RegistryKey -RegistryPath $registryPath -ExportPath $regExportPath
    }

    try {
        if ($isLocal) {
            # Local backup
            $backupResult = Export-RegistryKey -RegistryPath $RegistryPath -ExportPath $backupPath
        } else {
            # Remote backup
            $backupResult = Invoke-Command -ComputerName $ComputerName -ScriptBlock $scriptBlock `
                -ArgumentList $backupPath, $RegistryPath, $exportRegistryFunction
        }

        # Return the result of the backup
        if ($backupResult.Success) {
            Write-Host $backupResult.Message
        } else {
            Write-Error $backupResult.Message
        }

        return $backupResult
    } catch {
        Write-Error "Failed to back up the registry key '$RegistryPath' on $ComputerName. Error: $_"
        return @{
            Success    = $false
            BackupPath = $null
            Message    = "Failed to back up the registry key '$RegistryPath'. $_"
            ComputerName = $ComputerName
        }
    }
}
