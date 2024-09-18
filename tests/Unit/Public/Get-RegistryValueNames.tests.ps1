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

Describe 'Get-RegistryValueNames Function Tests' -Tag 'Public' {
    Context 'When retrieving all value names from a registry key using New-MockObject' {

        It 'Should return all the value names from the registry key' {
            # Mock the registry key object and the GetValueNames method
            $mockBaseKey = New-MockObject -Type Microsoft.Win32.RegistryKey -Methods @{
                GetValueNames = { return @('Value1', 'Value2', 'Value3') }
            }

            # Arrange
            # No additional arrangements needed

            # Act
            $result = Get-RegistryValueNames -BaseKey $mockBaseKey
            # Assert
            $result | Should -BeOfType [string]
            $result | Should -Contain 'Value1'
            $result | Should -Contain 'Value2'
            $result | Should -Contain 'Value3'
        }

        It 'Should throw a SecurityException if access is denied' {
            # Mock the registry key object and the GetValueNames method to throw a SecurityException
            $mockBaseKey = New-MockObject -Type Microsoft.Win32.RegistryKey -Methods @{
                GetValueNames = { throw [System.Security.SecurityException] "Access to the registry key is denied." }
            }

            # Act & Assert
            { Get-RegistryValueNames -BaseKey $mockBaseKey } | Should -Throw 'Exception calling "GetValueNames" with "0" argument(s): "Access to the registry key is denied."'
        }
    }
}
