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

    Remove-Item -Path Env:Registry_Path -ErrorAction SilentlyContinue
    Remove-Item -Path Env:Export_Path -ErrorAction SilentlyContinue
}

Describe 'Invoke-RegCommand Function Tests' -Tag 'Private' {



    Context 'When exporting registry keys' {

        It 'Should export registry key when valid paths are provided' {

            InModuleScope $script:dscModuleName {

                # Mock Invoke-Command to simulate reg.exe execution
                Mock -CommandName Invoke-Command -MockWith {
                    return $parameters
                }

                # Act
                $result = Invoke-RegCommand -RegistryPath 'HKCU\Software\MyKey' -ExportPath 'C:\Export\mykey.reg'

                # Assert
                Assert-MockCalled 'Invoke-Command' -Exactly -Times 1 -Scope IT

                $result.Operation | Should -Be 'EXPORT'
                $result.Path | Should -Be 'HKCU\Software\MyKey'
                $result.OutputFile | Should -Be 'C:\Export\mykey.reg'

            }
        }

        It 'Should use environment variables for paths if parameters are not provided' {

            InModuleScope $script:dscModuleName {

                Mock -CommandName Invoke-Command -MockWith {
                    return $parameters
                }

                # Set environment variables for the test
                $ENV:Registry_Path = 'HKLM\Software\MyApp'
                $ENV:Export_Path = 'D:\Backup\myapp.reg'

                # Act
                $result = Invoke-RegCommand

                # Assert
                Assert-MockCalled 'Invoke-Command' -Exactly -Times 1 -Scope It

                $result.Operation | Should -Be 'EXPORT'
                $result.Path | Should -Be 'HKLM\Software\MyApp'
                $result.OutputFile | Should -Be 'D:\Backup\myapp.reg'
            }
        }

        It 'Should throw an error if RegistryPath is null or empty' {

            InModuleScope $script:dscModuleName {
                # Test with missing RegistryPath
                $ENV:Registry_Path = $null
                { Invoke-RegCommand -ExportPath 'C:\Export\mykey.reg' } | Should -Throw "Path or OutputFile is null or empty."
            }
        }

        It 'Should throw an error if ExportPath is null or empty' {
            InModuleScope $script:dscModuleName {
                # Test with missing ExportPath
                $ENV:Export_Path = $null
                { Invoke-RegCommand -RegistryPath 'HKCU\Software\MyKey' } | Should -Throw "Path or OutputFile is null or empty."

            }
        }
    }

    Context 'Error handling' {
        It 'Should throw an error if Invoke-Command fails' {

            InModuleScope $script:dscModuleName {
                # Simulate Invoke-Command failure
                Mock -CommandName 'Invoke-Command' -MockWith {
                    throw "reg.exe failed."
                }

                { Invoke-RegCommand -RegistryPath 'HKCU\Software\MyKey' -ExportPath 'C:\Export\mykey.reg' } | Should -Throw "reg.exe failed."

            }
        }
    }

}
