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

Describe 'Get-RegistrySubKeyOperation' -Tag 'Private' {

    Context 'ByHive parameter set' {
        BeforeEach {
            # Mock the Open-RegistryKey function to prevent real registry access

        }

        It 'Should open registry key and return ParentKey and SubKeyName when ByHive is used' {

            InModuleScope -ScriptBlock {

                $mockParentKey = New-MockObject Microsoft.Win32.RegistryKey -Methods @{
                    DeleteSubKey = { param($subKey) return $true }
                } -Properties @{
                    Name        = "HKEY_LOCAL_MACHINE\SOFTWARE\MockedParentKey"
                    SubKeyCount = 5
                    ValueCount  = 10
                }

                # Mock the Open-RegistryKey function to return this mock object
                Mock -CommandName 'Open-RegistryKey' -MockWith {
                    return $mockParentKey
                }

                $localMachine = [Microsoft.Win32.RegistryHive]::LocalMachine

                $result = Get-RegistrySubKeyOperation -RegistryPath 'SOFTWARE\MyApp' -RegistryHive $localMachine -ComputerName 'RemotePC' -ParameterSetName 'ByHive'

                # Assert that Open-RegistryKey was called with expected parameters
                Assert-MockCalled 'Open-RegistryKey' -Exactly -Times 1 -ParameterFilter {
                    $RegistryPath -eq 'SOFTWARE' -and
                    $RegistryHive -eq 'LocalMachine' -and
                    $ComputerName -eq 'RemotePC'
                }

                # Verify the structure of the returned hashtable
                $result | Should -BeOfType 'System.Collections.Hashtable'
                $result.ParentKey | Should -Be $mockParentKey
                $result.ParentKey.Name | Should -Be 'HKEY_LOCAL_MACHINE\SOFTWARE\MockedParentKey'
                $result.SubKeyName | Should -Be 'MyApp'
            }
        }

        It 'Should throw an error if Open-RegistryKey fails' {
            # Simulate failure of Open-RegistryKey

            InModuleScope -ScriptBlock {
                Mock -CommandName 'Open-RegistryKey' -MockWith { throw }

                $message = 'Failed to open registry key: LocalMachine\SOFTWARE. ScriptHalted'

                $localMachine = [Microsoft.Win32.RegistryHive]::LocalMachine
                { Get-RegistrySubKeyOperation -RegistryPath 'SOFTWARE\MyApp' -RegistryHive $localMachine -ComputerName 'RemotePC' -ParameterSetName 'ByHive' } | Should -Throw $message

            }
        }

        It 'Should return ParentKey and SubKeyName when ByKey is used' {

            InModuleScope -ScriptBlock {

                # Prepare a mock parent key
                $mockParentKey = New-MockObject Microsoft.Win32.RegistryKey -Methods @{
                    DeleteSubKey = { param($subKey) return $true }
                } -Properties @{
                    Name        = "HKEY_LOCAL_MACHINE\SOFTWARE\MockedParentKey"
                    SubKeyCount = 5
                    ValueCount  = 10
                }

                $result = Get-RegistrySubKeyOperation -ParentKey $mockParentKey -SubKeyName 'Settings' -ParameterSetName 'ByKey'

                # Verify the structure of the returned hashtable
                $result | Should -BeOfType 'System.Collections.Hashtable'
                $result.ParentKey | Should -Be $mockParentKey
                $result.SubKeyName | Should -Be 'Settings'
            }
        }

        It 'Should throw an error if ParentKey is null' {
            InModuleScope -ScriptBlock {

                $message = @"
Value cannot be null.
Parameter name: ParentKey cannot be null.
"@

                { Get-RegistrySubKeyOperation -ParentKey $null -SubKeyName 'Settings' -ParameterSetName 'ByKey' } | Should -Throw $message

            }
        }
    }

    Context 'Invalid parameter set' {
        It 'Should throw an error for invalid parameter set' {

            InModuleScope -ScriptBlock {

                $message = @"
Invalid parameter set.
"@

                { Get-RegistrySubKeyOperation -RegistryPath 'SOFTWARE\MyApp' -RegistryHive 'LocalMachine' -ParameterSetName 'InvalidSet' } | Should -Throw $message

            }
        }
    }
}
