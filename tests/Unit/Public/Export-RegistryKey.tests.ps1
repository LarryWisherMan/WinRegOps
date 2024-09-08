BeforeAll {
    $script:dscModuleName = "WinRegOps"

    Import-Module -Name $script:dscModuleName

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

Describe 'Export-RegistryKey.tests.ps1 Tests' -Tag 'Public' {

    # Test for successful local export
    It 'should export registry key successfully on local machine' {
        # Mock the result of Invoke-Expression and manually set LASTEXITCODE to 0 (success)
        Mock Invoke-Expression { return $null }
        $global:LASTEXITCODE = 0  # Manually set LASTEXITCODE to simulate success

        # Define expected result
        $expected = @{
            Success      = $true
            BackupPath   = 'C:\Backups\MyApp.reg'
            Message      = "Registry key 'HKCU\Software\MyApp' successfully backed up to 'C:\Backups\MyApp.reg'."
            ComputerName = $env:COMPUTERNAME
        }

        # Call the function
        $result = Export-RegistryKey -RegistryPath 'HKCU\Software\MyApp' -ExportPath 'C:\Backups\MyApp.reg'

        #Write-Host ($result |Out-String)
        # Validate the result
        $result.success | Should -Be $True
        $result.message | Should -Be "Registry key 'HKCU\Software\MyApp' successfully backed up to 'C:\Backups\MyApp.reg'."
    }

    # Test for failed export
    It 'should return failure message when export fails' {
        # Mock the result of Invoke-Expression and set LASTEXITCODE to non-zero (failure)
        Mock Invoke-Expression { return $null }
        $global:LASTEXITCODE = 1

        # Define expected result
        $expected = @{
            Success      = $false
            BackupPath   = $null
            Message      = "Failed to export registry key 'HKCU\Software\MyApp'."
            ComputerName = $env:COMPUTERNAME
        }

        # Call the function
        $result = Export-RegistryKey -RegistryPath 'HKCU\Software\MyApp' -ExportPath 'C:\Backups\MyApp.reg' -ErrorAction Continue


        # Validate the result
        $result.success | Should -Be $false
        $result.message | Should -Be "Failed to export registry key 'HKCU\Software\MyApp'."
    }

    # Test for exception handling
    It 'should handle exceptions and return error message' {
        # Mock Invoke-Expression to throw an exception
        Mock Invoke-Expression { throw "Unexpected error" }

        # Define expected result
        $expected = @{
            Success      = $false
            BackupPath   = $null
            Message      = "Error during registry export for key 'HKCU\Software\MyApp'. Unexpected error"
            ComputerName = $env:COMPUTERNAME
        }

        # Call the function
        $result = Export-RegistryKey -RegistryPath 'HKCU\Software\MyApp' -ExportPath 'C:\Backups\MyApp.reg' -ErrorAction Continue

        # Validate the result
        $result.success | Should -Be $false
        $result.message | Should -Be "Error during registry export for key 'HKCU\Software\MyApp'. Unexpected error"
    }

    It 'should export registry key from a remote computer' {
        Mock Invoke-Expression { return $null }
        $global:LASTEXITCODE = 0

        $expected = @{
            Success      = $true
            BackupPath   = '\\RemotePC\Backups\MyApp.reg'
            Message      = "Registry key 'HKCU\Software\MyApp' successfully backed up to '\\RemotePC\Backups\MyApp.reg'."
            ComputerName = 'RemotePC'
        }



        $result = Export-RegistryKey -RegistryPath 'HKCU\Software\MyApp' -ExportPath '\\RemotePC\Backups\MyApp.reg' -ComputerName 'RemotePC'
        write-host ($result | Out-String)

        $result.Success | Should -Be $true
        $result.Message | Should -Be "Registry key 'HKCU\Software\MyApp' successfully backed up to '\\RemotePC\Backups\MyApp.reg'."
    }

}
