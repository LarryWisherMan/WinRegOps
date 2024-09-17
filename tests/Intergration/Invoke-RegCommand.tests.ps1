BeforeAll {
    $script:dscModuleName = "WinRegOps"

    # Import the module being tested
    Import-Module -Name $script:dscModuleName

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force

    # Clean up environment variables
    Remove-Item -Path Env:Registry_Path -ErrorAction SilentlyContinue
    Remove-Item -Path Env:Export_Path -ErrorAction SilentlyContinue

}

Describe 'Invoke-RegCommand Integration Tests using TestRegistry' -Tag 'Integration' {

    Context 'Exporting a registry key using reg.exe' {
        BeforeAll {
            # Set up a test registry key in TestRegistry
            New-Item -Path "TestRegistry:\TestKey" -Force | Out-Null
            New-ItemProperty -Path "TestRegistry:\TestKey" -Name "TestValue" -Value "123" | Out-Null
        }

        It 'Should export the TestRegistry key to the specified file' {
            # Act: Call the Invoke-RegCommand function
            InModuleScope -ScriptBlock {
                # Set the environment variables to point to TestRegistry and TestDrive for testing
                $env:Registry_Path = "$(Get-PSDrive TestRegistry | Select-Object -ExpandProperty Root)\TestKey"
                $env:Export_Path = "$(Get-PSDrive -Name TestDrive |Select-Object -ExpandProperty Root)\TestKey.Reg"



                $result = Invoke-RegCommand

                Write-Host $result

            }

            # Assert: Verify the export file was created in TestDrive
            Test-Path -Path $env:Export_Path | Should -Be $true

            # Optional: Verify that the contents of the exported file contain the expected registry data
            $exportedContent = (Get-Content -Path $env:Export_Path -raw).Trim()

            $ExpectedContent = @"
Windows Registry Editor Version 5.00

[$env:registry_Path]
"TestValue"="123"
"@


            $exportedContent | Should -Be $ExpectedContent
        }

        It 'Should throw an error if the registry path or export path is empty' {
            # Arrange: Clear the environment variables
            $env:Registry_Path = $null
            $env:Export_Path = $null

            InModuleScope -ScriptBlock {
                # Act & Assert: Expect an error due to missing parameters
                { Invoke-RegCommand } | Should -Throw "Path or OutputFile is null or empty."
            }
        }
    }

    Context 'Backup-RegistryKey - Local Backup' {
        It 'Should successfully back up the local registry key' {

            New-Item -Path "TestRegistry:\TestKey" -Force | Out-Null
            New-ItemProperty -Path "TestRegistry:\TestKey" -Name "TestValue" -Value "123" | Out-Null

            $backupDirectory = "$(Get-PSDrive -Name TestDrive |Select-Object -ExpandProperty Root)\RegProfBackup"
            $registryPath = "$(Get-PSDrive TestRegistry | Select-Object -ExpandProperty Root)\TestKey"
            $localComputerName = $env:COMPUTERNAME



            # Act
            $result = Backup-RegistryKey -RegistryPath $registryPath -BackupDirectory $backupDirectory

            $exportedContent = (Get-Content -Path $result.BackupPath -raw).Trim()

            $ExpectedContent = @"
Windows Registry Editor Version 5.00

[$registryPath]
"TestValue"="123"
"@


            $exportedContent | Should -Be $ExpectedContent
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Success | Should -Be $true
            $result.BackupPath | Should -Not -BeNullOrEmpty
            $result.BackUpPath | Should -BeLike "$backupDirectory*.reg"
            Test-Path $result.BackupPath | Should -Be $true
            $result.Message | Should -Be "Registry key backed up successfully."
            $result.ComputerName | Should -Be $localComputerName
        }
    }
}
