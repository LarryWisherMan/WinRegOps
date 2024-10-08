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

Describe 'Remove-RegistrySubKey function tests' -Tag 'Public' {

    Context 'ByHive parameter set tests' {
        It 'Should throw an error if mandatory parameters are missing' {
            { Remove-RegistrySubKey -RegistryHive [Microsoft.Win32.RegistryHive]::LocalMachine -confirm:$false } | Should -Throw
        }

        It 'Should validate RegistryHive and RegistryPath parameters' {
            # Arrange
            # Mocking the ParentKey object and its methods
            $mockParentKey = New-MockObject Microsoft.Win32.RegistryKey -Methods @{
                DeleteSubKey = { param($subKey) return $true }
            }

            # Mock Open-RegistryKey to return the mocked ParentKey
            Mock -CommandName Open-RegistryKey { return $mockParentKey }

            Mock -CommandName Invoke-DeleteSubKey { return $true } -ModuleName $Script:dscModuleName

            $hive = [Microsoft.Win32.RegistryHive]::LocalMachine
            # Act
            Remove-RegistrySubKey -RegistryHive $hive -RegistryPath "SOFTWARE\MyApp" -Confirm:$false
            # Assert
            # Ensure that Open-RegistryKey was called
            Assert-MockCalled -CommandName Open-RegistryKey -Exactly 1 -Scope It

            # Ensure that Invoke-DeleteSubKey was called
            Assert-MockCalled -CommandName Invoke-DeleteSubKey -Exactly 1 -Scope It -ParameterFilter { $SubKeyName -eq "MyApp" } -ModuleName $Script:dscModuleName
        }

        It 'Should process the registry key deletion' {
            # Arrange
            $mockParentKey = New-MockObject Microsoft.Win32.RegistryKey -Methods @{
                DeleteSubKey = { param($subKey) return $true }
            }

            Mock Open-RegistryKey { return $mockParentKey }
            Mock Invoke-DeleteSubKey { } -ModuleName $Script:dscModuleName

            $hive = [Microsoft.Win32.RegistryHive]::LocalMachine
            # Act
            Remove-RegistrySubKey -RegistryHive $hive -RegistryPath "SOFTWARE\MyApp" -Confirm:$false

            # Assert
            Assert-MockCalled -CommandName Open-RegistryKey -Exactly 1 -Scope It
            Assert-MockCalled -CommandName Invoke-DeleteSubKey -Exactly 1 -Scope It -ModuleName $Script:dscModuleName
        }


        It 'Should respect ShouldProcess for safety confirmation' {
            # Arrange
            $mockParentKey = New-MockObject Microsoft.Win32.RegistryKey -Methods @{
                DeleteSubKey = { param($subKey) return $true }
            }

            # Mock Open-RegistryKey to return the mocked ParentKey
            Mock Open-RegistryKey { return $mockParentKey }
            Mock Invoke-DeleteSubKey { }

            # Mock ShouldProcess by using a ParameterFilter to simulate confirmation behavior
            Mock Remove-RegistrySubKey -ParameterFilter {
                $PSCmdlet.ShouldProcess('SOFTWARE\MyApp', 'Removing registry subkey') -eq $true
            }

            $hive = [Microsoft.Win32.RegistryHive]::LocalMachine

            # Act
            Remove-RegistrySubKey -RegistryHive $hive  -RegistryPath "SOFTWARE\MyApp" -Confirm:$false

            # Assert
            Assert-MockCalled -CommandName Open-RegistryKey -Exactly 1 -Scope It
            Assert-MockCalled -CommandName Invoke-DeleteSubKey -Exactly 1 -Scope It
        }
    }

    Context 'ByKey parameter set tests' {
        It 'Should throw an error if ParentKey is null' {
            { Remove-RegistrySubKey -ParentKey $null -SubKeyName "TestSubKey" -confirm:$false } | Should -Throw -ErrorId 'ParameterArgumentValidationErrorNullNotAllowed,Remove-RegistrySubKey'
        }

        It 'Should remove a subkey when ParentKey is valid' {
            # Arrange
            # Arrange
            $mockParentKey = New-MockObject Microsoft.Win32.RegistryKey -Methods @{
                DeleteSubKey = { param($subKey) return $true }
            }
            Mock Invoke-DeleteSubKey {} -ModuleName $Script:dscModuleName
            # Act
            Remove-RegistrySubKey -ParentKey $mockParentKey -SubKeyName "Settings" -Confirm:$false

            # Assert
            Assert-MockCalled -CommandName Invoke-DeleteSubKey -Exactly 1 -Scope It -ModuleName $Script:dscModuleName
        }
    }

    Context 'Error handling tests' {
        It 'Should throw an exception for invalid subkey name' {
            { Remove-RegistrySubKey -RegistryHive [Microsoft.Win32.RegistryHive]::LocalMachine -RegistryPath "" } | Should -Throw -ErrorId 'ParameterArgumentTransformationError,Remove-RegistrySubKey'
        }

        It 'Should throw an exception if unable to open the registry key' {
            Mock Open-RegistryKey { throw "Failed to open registry key" }

            { Remove-RegistrySubKey -RegistryHive [Microsoft.Win32.RegistryHive]::LocalMachine -RegistryPath "Invalid\Path" } | Should -Throw
        }
    }
}
