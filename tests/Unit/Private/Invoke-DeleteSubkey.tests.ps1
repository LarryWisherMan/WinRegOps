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
}

Describe 'Invoke-DeleteSubKey Unit Tests' -Tag 'private' {
    Context 'Valid Input Tests' {
        It 'Should delete the subkey when provided with valid ParentKey and SubKeyName' {
            # Act: Call the function with valid ParentKey and SubKeyName
            InModuleScope -ScriptBlock {

                $mockParentKey = New-MockObject Microsoft.Win32.RegistryKey -Methods @{
                    DeleteSubKey = { param($subKey, $throwOnMissing)

                        return @{
                            SubKey         = $subKey
                            ThrowOnMissing = $throwOnMissing
                        }
                    }
                }

                $return = Invoke-DeleteSubKey -ParentKey $mockParentKey -SubKeyName 'TestSubKey'
                $return.subkey | Should -Be 'TestSubKey'
                $return.ThrowOnMissing | Should -Be $true
            }
        }

        It 'Should not throw an error if the subkey does not exist and ThrowOnMissingSubKey is $false' {
            # Act: Call the function with ThrowOnMissingSubKey set to $false
            InModuleScope -ScriptBlock {

                $mockParentKey = New-MockObject Microsoft.Win32.RegistryKey -Methods @{
                    DeleteSubKey = { param($subKey, $throwOnMissing)

                        return @{
                            SubKey         = $subKey
                            ThrowOnMissing = $throwOnMissing
                        }
                    }
                }

                $return = Invoke-DeleteSubKey -ParentKey $mockParentKey -SubKeyName 'NonExistentSubKey' -ThrowOnMissingSubKey $false

                $return.subkey | Should -Be 'NonExistentSubKey'
                $return.ThrowOnMissing | Should -Be $false


            }
        }
    }

    Context 'Invalid Input Tests' {
        It 'Should throw an ArgumentNullException when ParentKey is $null' {
            # Act & Assert: Expect ArgumentNullException when ParentKey is null

            InModuleScope -ScriptBlock {

                $message = @"
Value cannot be null.
Parameter name: ParentKey cannot be null.
"@
                { Invoke-DeleteSubKey -ParentKey $null -SubKeyName 'TestSubKey' } | Should -Throw $message
            }

        }

        It 'Should throw an ArgumentNullException when SubKeyName is $null or empty' {
            # Act & Assert: Expect ArgumentNullException when SubKeyName is null

            InModuleScope -ScriptBlock {

                $mockParentKey = New-MockObject Microsoft.Win32.RegistryKey -Methods @{
                    DeleteSubKey = { param($subKey) return $true }
                } -Properties @{
                    Name         = "HKEY_LOCAL_MACHINE\SOFTWARE\MockedParentKey"
                    SubKeyCount  = 5
                    ValueCount   = 10
                    DeleteSubKey = { param($subKey, $throwOnMissing)

                        return @{
                            SubKey         = $subKey
                            ThrowOnMissing = $throwOnMissing
                        }
                    }
                }
                $message = @"
Value cannot be null.
Parameter name: SubKeyName cannot be null or Empty.
"@

                { Invoke-DeleteSubKey -ParentKey $mockParentKey -SubKeyName $null } | Should -Throw $message
                { Invoke-DeleteSubKey -ParentKey $mockParentKey -SubKeyName '' } | Should -Throw $message

            }
        }
    }

    Context 'Error Handling Tests' {
        It 'Should throw an error if DeleteSubKey fails' {
            InModuleScope -ScriptBlock {

                $mockParentKey = New-MockObject Microsoft.Win32.RegistryKey -Methods @{
                    DeleteSubKey = { throw "Test error" }
                }

                $message = 'Exception calling "DeleteSubKey" with "2" argument(s): "Test error"'

                { Invoke-DeleteSubKey -ParentKey $mockParentKey -SubKeyName 'TestSubKey' } | Should -Throw $message

            }
        }
    }
}
