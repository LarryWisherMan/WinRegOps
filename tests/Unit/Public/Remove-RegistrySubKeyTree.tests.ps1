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

Describe 'Remove-RegistrySubKeyTree function tests' -Tag 'Public' {

    Context 'ByHive parameter set tests' {
        It 'Should throw an error if mandatory parameters are missing' {
            { Remove-RegistrySubKeyTree -RegistryHive [Microsoft.Win32.RegistryHive]::LocalMachine -Confirm:$false } | Should -Throw
        }

        It 'Should validate RegistryHive and RegistryPath parameters' {
            # Arrange
            $mockParentKey = New-MockObject Microsoft.Win32.RegistryKey -Methods @{
                DeleteSubKeyTree = { param($subKey) return $true }
            }

            # Mock Open-RegistryKey to return the mocked ParentKey
            Mock -CommandName Open-RegistryKey { return $mockParentKey }

            Mock -CommandName Invoke-DeleteSubKeyTree { return $true } -ModuleName $Script:dscModuleName

            $hive = [Microsoft.Win32.RegistryHive]::LocalMachine

            # Act
            Remove-RegistrySubKeyTree -RegistryHive $hive -RegistryPath "SOFTWARE\MyApp" -Confirm:$false

            # Assert
            Assert-MockCalled -CommandName Open-RegistryKey -Exactly 1 -Scope It
            Assert-MockCalled -CommandName Invoke-DeleteSubKeyTree -Exactly 1 -Scope It -ParameterFilter { $SubKeyName -eq "MyApp" } -ModuleName $Script:dscModuleName
        }

        It 'Should process the registry key deletion' {
            # Arrange
            $mockParentKey = New-MockObject Microsoft.Win32.RegistryKey -Methods @{
                DeleteSubKeyTree = { param($subKey) return $true }
            }

            Mock Open-RegistryKey { return $mockParentKey }
            Mock Invoke-DeleteSubKeyTree { } -ModuleName $Script:dscModuleName

            $hive = [Microsoft.Win32.RegistryHive]::LocalMachine

            # Act
            Remove-RegistrySubKeyTree -RegistryHive $hive -RegistryPath "SOFTWARE\MyApp" -Confirm:$false

            # Assert
            Assert-MockCalled -CommandName Open-RegistryKey -Exactly 1 -Scope It
            Assert-MockCalled -CommandName Invoke-DeleteSubKeyTree -Exactly 1 -Scope It -ModuleName $Script:dscModuleName
        }

        It 'Should respect ShouldProcess for safety confirmation' {
            # Arrange
            $mockParentKey = New-MockObject Microsoft.Win32.RegistryKey -Methods @{
                DeleteSubKeyTree = { param($subKey) return $true }
            }

            # Mock Open-RegistryKey to return the mocked ParentKey
            Mock Open-RegistryKey { return $mockParentKey }
            Mock Invoke-DeleteSubKeyTree { } -ModuleName $Script:dscModuleName

            # Act
            Remove-RegistrySubKeyTree -RegistryHive LocalMachine -RegistryPath "SOFTWARE\MyApp" -Confirm:$false

            # Assert
            Assert-MockCalled -CommandName Open-RegistryKey -Exactly 1 -Scope It
            Assert-MockCalled -CommandName Invoke-DeleteSubKeyTree -Exactly 1 -Scope It -ModuleName $Script:dscModuleName
        }
    }

    Context 'ByKey parameter set tests' {
        It 'Should throw an error if ParentKey is null' {
            { Remove-RegistrySubKeyTree -ParentKey $null -SubKeyName "TestSubKey" -Confirm:$false } | Should -Throw -ErrorId 'ParameterArgumentValidationErrorNullNotAllowed,Remove-RegistrySubKeyTree'
        }

        It 'Should remove a subkey when ParentKey is valid' {
            # Arrange
            $mockParentKey = New-MockObject Microsoft.Win32.RegistryKey -Methods @{
                DeleteSubKeyTree = { param($subKey) return $true }
            }

            Mock Invoke-DeleteSubKeyTree {} -ModuleName $Script:dscModuleName

            # Act
            Remove-RegistrySubKeyTree -ParentKey $mockParentKey -SubKeyName "Settings" -Confirm:$false

            # Assert
            Assert-MockCalled -CommandName Invoke-DeleteSubKeyTree -Exactly 1 -Scope It -ModuleName $Script:dscModuleName
        }
    }

    Context 'Error handling tests' {
        It 'Should throw an exception for invalid subkey name' {
            { Remove-RegistrySubKeyTree -RegistryHive [Microsoft.Win32.RegistryHive]::LocalMachine -RegistryPath "" } | Should -Throw -ErrorId 'ParameterArgumentTransformationError,Remove-RegistrySubKeyTree'
        }

        It 'Should throw an exception if unable to open the registry key' {
            Mock Open-RegistryKey { throw "Failed to open registry key" }

            { Remove-RegistrySubKeyTree -RegistryHive [Microsoft.Win32.RegistryHive]::LocalMachine -RegistryPath "Invalid\Path" } | Should -Throw
        }
    }
}
