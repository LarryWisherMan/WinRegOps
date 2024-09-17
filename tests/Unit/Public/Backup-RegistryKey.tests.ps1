

BeforeAll {
    $script:dscModuleName = "WinRegOps"
    Import-Module -Name $script:dscModuleName

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName

    $helperPath = "$PSScriptRoot/../../Helpers/Log-TestDetails.ps1"
    . $helperPath

    $ENV:RegBackupDirectory = "TestDrive:\Backups"

}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force

    remove-item -path Env:RegBackupDirectory -ErrorAction SilentlyContinue
}

Describe 'Backup-RegistryKey function tests' -Tag 'Public' {

    It 'should call Get-DirectoryPath and Test-DirectoryExists using TestDrive' {
        # Use TestDrive for file system isolation
        Mock Get-DirectoryPath { return "TestDrive:\RegProfBackup" }
        Mock Test-DirectoryExistence {}
        Mock New-UniqueFilePath { return "TestDrive:\ProfileListBackup_20220101_010101.reg" }
        Mock Export-RegistryKey { return @{
                Success      = $true
                BackupPath   = "TestDrive:\ProfileListBackup_20220101_010101.reg"
                Message      = "Registry key backed up successfully."
                ComputerName = "localhost"
            } }

        Backup-RegistryKey -RegistryPath 'TestRegistry:\Software\MyApp'

        # Validate that the required functions were called
        Assert-MockCalled Get-DirectoryPath -Exactly 1 -Scope It
        Assert-MockCalled Test-DirectoryExistence -Exactly 1 -Scope It
    }

    It 'should call Export-RegistryKey for a local operation using TestRegistry' {
        # Mock file paths and ensure TestDrive is used for isolation
        Mock Get-DirectoryPath { return "TestDrive:\RegProfBackup" }
        Mock New-UniqueFilePath { return "TestDrive:\ProfileListBackup_20220101_010101.reg" }
        Mock Export-RegistryKey { return @{
                Success      = $true
                BackupPath   = "TestDrive:\ProfileListBackup_20220101_010101.reg"
                Message      = "Registry key backed up successfully."
                ComputerName = $env:COMPUTERNAME  # Simulate local computer name in the result
            } }

        # Call the function for local operation
        $result = Backup-RegistryKey -RegistryPath 'TestRegistry:\Software\MyApp'

        # Validate that Export-RegistryKey was called (local operation)
        Assert-MockCalled Export-RegistryKey -Exactly 1 -Scope It

        # Verify that the ComputerName in the result matches the local computer
        $result.ComputerName | Should -Be $env:COMPUTERNAME

        # Ensure the result is correct
        $result | Should -BeOfType [hashtable]
        $result.Success | Should -Be $true
    }

    It 'should call Invoke-Command for a remote operation using TestDrive' {
        # Mock external functions
        Mock Get-DirectoryPath { return "\\RemotePC\TestDrive$\RegProfBackup" }
        Mock Test-DirectoryExistence {}
        Mock New-UniqueFilePath { return "\\RemotePC\TestDrive$\ProfileListBackup_20220101_010101.reg" }

        Mock Export-RegistryKey { return @{
                Success      = $true
                BackupPath   = "\\RemotePC\TestDrive$\ProfileListBackup_20220101_010101.reg"
                Message      = "Registry key backed up successfully."
                ComputerName = 'RemotePC'
            } }

        Mock Get-FunctionScriptBlock { return @{
                Success      = $true
                BackupPath   = "\\RemotePC\TestDrive$\ProfileListBackup_20220101_010101.reg"
                Message      = "Registry key backed up successfully."
                ComputerName = 'RemotePC'
            } }

        # Mock the result of Invoke-Command to simulate a successful remote operation
        Mock Invoke-Command {
            return @{
                Success      = $true
                BackupPath   = "\\RemotePC\TestDrive$\ProfileListBackup_20220101_010101.reg"
                Message      = "Registry key backed up successfully."
                ComputerName = 'RemotePC'
            }
        }

        # Call the function with remote parameters
        $result = Backup-RegistryKey -ComputerName 'RemotePC' -RegistryPath 'TestRegistry:\Software\MyApp' -BackupDirectory "TestDrive:\Backups"
        # Verify that Invoke-Command was called for remote backup
        Assert-MockCalled Invoke-Command -Exactly 1 -Scope It -ParameterFilter {
            $ComputerName -eq 'RemotePC' -and $ScriptBlock -ne $null
        }

        # Ensure the parameters in the result are correct
        $result.ComputerName | Should -Be 'RemotePC'
        $result.Success | Should -Be $true
    }

    It 'should return an error if backup fails using TestDrive' {
        # Mock functions
        Mock -ModuleName $Script:dscModuleName -CommandName Export-RegistryKey { return @{ Success = $false; Message = "Failed to export key." } }
        Mock -ModuleName $Script:dscModuleName -CommandName  Test-DirectoryExistence {}
        Mock -ModuleName $Script:dscModuleName -CommandName  New-UniqueFilePath { return "TestDrive:\ProfileListBackup_20220101_010101.reg" }

        try
        {
            # Call the function
            $result = Backup-RegistryKey -RegistryPath 'TestRegistry:\Software\MyApp' -ErrorAction Continue
        }

        catch
        {
            #$out $_.Exception.Message
        }


        # Validate the error response
        $result.Success | Should -Be $false
        $result.Message | Should -Be "Failed to export key."
    }



    It 'should handle exceptions and return an error message using TestDrive and TestRegistry' {
        # Mock functions
        Mock Export-RegistryKey { throw [Exception]::new("Unexpected error") }
        Mock Test-DirectoryExistence {}
        Mock New-UniqueFilePath { return "TestDrive:\ProfileListBackup_20220101_010101.reg" }

        try
        {
            # Call the function
            $result = Backup-RegistryKey -RegistryPath 'TestRegistry:\Software\MyApp' -ErrorAction Continue
        }

        catch
        {
            #$result = $_.Exception.Message
        }

        # Validate that $result is not null before making assertions
        $result | Should -Not -BeNullOrEmpty

        # Validate the error response contains the key part of the message
        $result.Success | Should -Be $false
        $result.Message | Should -Be "Failed to back up the registry key 'TestRegistry:\Software\MyApp'. Error: Unexpected error"
    }


}
