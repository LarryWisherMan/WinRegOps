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

Describe 'Get-RegistrySubKey function tests' -Tag 'Public' {

    BeforeEach {
        # Mock the RegistryKey object and its OpenSubKey method
        $mockRegistryKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
            OpenSubKey = { param($name, $options)
                switch ($name)
                {
                    'ValidSubKey'
                    {
                        return 'MockedSubKey'
                    }
                    'InvalidSubKey'
                    {
                        throw [System.IO.IOException] "SubKey not found"
                    }
                    default
                    {
                        return $null
                    }
                }
            }
        }
    }

    Context 'BooleanSet' {
        It 'Should return a writable registry subkey' {
            # Arrange
            $name = 'ValidSubKey'
            $writable = $true

            # Act
            $result = Get-RegistrySubKey -BaseKey $mockRegistryKey -Name $name -Writable $writable

            # Assert
            $result | Should -Be 'MockedSubKey'
        }

        It 'Should return a read-only registry subkey' {
            # Arrange
            $name = 'ValidSubKey'
            $writable = $false

            # Act
            $result = Get-RegistrySubKey -BaseKey $mockRegistryKey -Name $name -Writable $writable

            # Assert
            $result | Should -Be 'MockedSubKey'
        }
    }

    Context 'PermissionCheckSet' {
        It 'Should open a registry subkey with Default permission check' {
            # Arrange
            $name = 'ValidSubKey'
            $permissionCheck = [Microsoft.Win32.RegistryKeyPermissionCheck]::Default

            # Act
            $result = Get-RegistrySubKey -BaseKey $mockRegistryKey -Name $name -PermissionCheck $permissionCheck

            # Assert
            $result | Should -Be 'MockedSubKey'
        }

        It 'Should open a registry subkey with ReadSubTree permission check' {
            # Arrange
            $name = 'ValidSubKey'
            $permissionCheck = [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadSubTree

            # Act
            $result = Get-RegistrySubKey -BaseKey $mockRegistryKey -Name $name -PermissionCheck $permissionCheck

            # Assert
            $result | Should -Be 'MockedSubKey'
        }
    }

    Context 'RightsSet' {
        It 'Should open a registry subkey with ReadKey rights' {
            # Arrange
            $name = 'ValidSubKey'
            $rights = [System.Security.AccessControl.RegistryRights]::ReadKey

            # Act
            $result = Get-RegistrySubKey -BaseKey $mockRegistryKey -Name $name -Rights $rights

            # Assert
            $result | Should -Be 'MockedSubKey'
        }

        It 'Should throw an IOException for an invalid subkey' {
            # Arrange
            $name = 'InvalidSubKey'
            $rights = [System.Security.AccessControl.RegistryRights]::ReadKey

            # Act & Assert
            { Get-RegistrySubKey -BaseKey $mockRegistryKey -Name $name -Rights $rights } | Should -Throw -ExpectedMessage  'Exception calling "OpenSubKey" with "2" argument(s): "SubKey not found"'
        }
    }

    Context 'Error Handling' {
        It 'Should throw a SecurityException when access is denied' {
            # Mock the OpenSubKey method to throw a SecurityException
            $mockRegistryKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
                OpenSubKey = { param($name, $options)
                    throw [System.Security.SecurityException] "Access denied"
                }
            }

            # Arrange
            $name = 'ValidSubKey'
            $writable = $true

            # Act & Assert
            { Get-RegistrySubKey -BaseKey $mockRegistryKey -Name $name -Writable $writable } | Should -Throw -ExpectedMessage 'Exception calling "OpenSubKey" with "2" argument(s): "Access denied"'
        }

        It 'Should throw an Unknown parameter set error' {
            # Arrange
            $mockRegistryKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
                OpenSubKey = { throw "Unknown parameter set" }
            }

            $name = 'ValidSubKey'

            # Act & Assert
            { Get-RegistrySubKey -BaseKey $mockRegistryKey -Name $name -Writable $true } | Should -Throw -ExpectedMessage 'Exception calling "OpenSubKey" with "2" argument(s): "Unknown parameter set"'
        }
    }
}
