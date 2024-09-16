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

Describe 'Get-RegistryValue function tests' -Tag 'Public' {

    BeforeEach {
        $mockRegistryKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
            GetValue = { param($valueName, $defaultValue, $options)
                if ($valueName -eq 'Exists')
                {
                    return 'RegistryValue'
                }
                elseif ($valueName -eq 'NotFound' -and $defaultValue)
                {
                    return $defaultValue
                }
                elseif ($valueName -eq 'ExpandEnvVar' -and $options -eq [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
                {
                    return '%SystemRoot%\System32'
                }
                else
                {
                    return $null
                }
            }
        }
    }

    Context 'When the registry value exists' {
        It 'Should return the registry value' {

            # Arrange
            $valueName = 'Exists'

            # Act
            $result = Get-RegistryValue -BaseKey $mockRegistryKey -ValueName $valueName

            # Assert
            $result | Should -Be 'RegistryValue'
        }
    }

    Context 'When the registry value does not exist' {
        It 'Should return null if no default value is provided' {
            # Arrange
            $valueName = 'NotFound'

            # Act
            $result = Get-RegistryValue -BaseKey $mockRegistryKey -ValueName $valueName

            # Assert
            $result | Should -BeNullOrEmpty
        }

        It 'Should return the default value if specified' {
            # Arrange
            $valueName = 'NotFound'
            $defaultValue = 'DefaultFallback'

            # Act
            $result = Get-RegistryValue -BaseKey $mockRegistryKey -ValueName $valueName -DefaultValue $defaultValue

            # Assert
            $result | Should -Be 'DefaultFallback'
        }
    }

    Context 'When using registry value options' {
        It 'Should retrieve value without expanding environment variables' {
            # Arrange
            $valueName = 'ExpandEnvVar'
            $options = [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames

            # Act
            $result = Get-RegistryValue -BaseKey $mockRegistryKey -ValueName $valueName -Options $options

            # Assert
            $result | Should -Be '%SystemRoot%\System32'
        }

        It 'Should return null for non-existent value with options' {
            # Arrange
            $valueName = 'NonExistentWithOptions'
            $options = [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames

            # Act
            $result = Get-RegistryValue -BaseKey $mockRegistryKey -ValueName $valueName -Options $options

            # Assert
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When options are none and a default value is provided' {
        It 'Should return the value if it exists, ignoring the default value' {
            # Arrange
            $valueName = 'Exists'
            $defaultValue = 'SomeDefault'

            # Act
            $result = Get-RegistryValue -BaseKey $mockRegistryKey -ValueName $valueName -DefaultValue $defaultValue

            # Assert
            $result | Should -Be 'RegistryValue'
        }

        It 'Should return the default value if the registry value does not exist' {
            # Arrange
            $valueName = 'NotFound'
            $defaultValue = 'DefaultValue'

            # Act
            $result = Get-RegistryValue -BaseKey $mockRegistryKey -ValueName $valueName -DefaultValue $defaultValue

            # Assert
            $result | Should -Be 'DefaultValue'
        }
    }

    Context 'Error Handling' {

        It 'Should throw a SecurityException when access is denied' {

            # Arrange
            $valueName = 'SecurityError'

            $mockRegistryKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
                GetValue = { param($valueName, $defaultValue, $options)
                    throw [System.Security.SecurityException]
                }
            }

            # Act & Assert
            { Get-RegistryValue -BaseKey $mockRegistryKey -ValueName $valueName } | Should -Throw -ExpectedMessage 'Exception calling "GetValue" with "1" argument(s): "System.Security.SecurityException"'
        }

        It 'Should throw an ObjectDisposedException when the registry key is closed' {


            # Arrange
            $valueName = 'DisposedError'

            $mockRegistryKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
                GetValue = { param($valueName, $defaultValue, $options)
                    throw  [System.ObjectDisposedException]
                }
            }

            # Act & Assert
            { Get-RegistryValue -BaseKey $mockRegistryKey -ValueName $valueName } | Should -Throw -ExpectedMessage 'Exception calling "GetValue" with "1" argument(s): "System.ObjectDisposedException"'

        }

        It 'Should throw an IOException when the registry key is marked for deletion' {

            $mockRegistryKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
                GetValue = { param($valueName, $defaultValue, $options)
                    throw  [System.IO.IOException]
                }
            }
            # Arrange
            $valueName = 'IOError'

            # Act & Assert
            { Get-RegistryValue -BaseKey $mockRegistryKey -ValueName $valueName } | Should -Throw -ExpectedMessage 'Exception calling "GetValue" with "1" argument(s): "System.IO.IOException"'
        }

        It 'Should throw an ArgumentException for invalid options' {
            # Arrange
            $valueName = 'ArgumentError'
            $invalidOptions = [Microsoft.Win32.RegistryOptions]::Volatile


            $mockRegistryKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
                GetValue = { param($valueName, $defaultValue, $options)
                    throw [System.ArgumentException]

                }
            }

            # Act & Assert
            { Get-RegistryValue -BaseKey $mockRegistryKey -ValueName $valueName -Options $invalidOptions } | Should -Throw -ExpectedMessage 'Exception calling "GetValue" with "3" argument(s): "System.ArgumentException"'
        }

        It 'Should throw an UnauthorizedAccessException when access rights are insufficient' {

            $mockRegistryKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
                GetValue = { param($valueName, $defaultValue, $options)
                    throw [System.UnauthorizedAccessException]

                }
            }

            # Arrange
            $valueName = 'UnauthorizedError'

            # Act & Assert
            { Get-RegistryValue -BaseKey $mockRegistryKey -ValueName $valueName } | Should -Throw -ExpectedMessage 'Exception calling "GetValue" with "1" argument(s): "System.UnauthorizedAccessException"'
        }
    }

}
