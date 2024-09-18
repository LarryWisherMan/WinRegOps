BeforeAll {
    $script:dscModuleName = "WinRegOps"

    # Import the module containing the registry functions
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

Describe 'New-RegistryKeyValuesObject Function Tests' -Tag 'Public' {
    Context 'When exporting values from a registry key using New-MockObject' {

        BeforeEach {
            # Mock dependencies used in the function
            Mock Get-RegistrySubKey {
                $mockSubKey = New-MockObject -Type Microsoft.Win32.RegistryKey -Properties @{ Name = 'SOFTWARE\MyApp\SubKey' }
                return $mockSubKey
            }
            Mock Get-RegistryValueNames { return @('Value1', 'Value2') }
            Mock Get-RegistryValue { return "MockedValue" }
            Mock Get-RegistryValueKind { return [Microsoft.Win32.RegistryValueKind]::String }
        }

        It 'Should return a custom object for the root registry key' {
            # Arrange
            $mockRegistryKey = New-MockObject -Type Microsoft.Win32.RegistryKey -Properties @{ Name = 'SOFTWARE\MyApp' }

            # Act
            $result = New-RegistryKeyValuesObject -RegistryKey $mockRegistryKey

            # Assert
            $result | Should -BeOfType 'PSCustomObject'
            $result.RegistryPath | Should -Be 'SOFTWARE\MyApp'
            $result.Values['Value1'].Value | Should -Be 'MockedValue'
            $result.Values['Value1'].Type | Should -Be 'String'
        }

        It 'Should return a custom object for a specific subkey' {
            # Arrange
            $mockRegistryKey = New-MockObject -Type Microsoft.Win32.RegistryKey -Properties @{ Name = 'SOFTWARE\MyApp' }

            # Act
            $result = New-RegistryKeyValuesObject -RegistryKey $mockRegistryKey -SubKeyName 'SubKey'

            # Assert
            $result | Should -BeOfType 'PSCustomObject'
            $result.RegistryPath | Should -Be 'SOFTWARE\MyApp\SubKey'
            $result.Values['Value1'].Value | Should -Be 'MockedValue'
            $result.Values['Value1'].Type | Should -Be 'String'
        }

        It 'Should throw an exception if the subkey does not exist' {
            # Arrange: Mock Get-RegistrySubKey to return $null for non-existing subkey
            Mock Get-RegistrySubKey { return $null }
            $mockRegistryKey = New-MockObject -Type Microsoft.Win32.RegistryKey -Properties @{ Name = 'SOFTWARE\MyApp' }

            # Act & Assert
            { New-RegistryKeyValuesObject -RegistryKey $mockRegistryKey -SubKeyName 'NonExistentSubKey' } | Should -Throw "Cannot bind argument to parameter 'BaseKey' because it is null."
        }
    }
}
