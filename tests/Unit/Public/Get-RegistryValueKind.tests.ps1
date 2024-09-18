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

Describe 'Get-RegistryValueKind Function Tests' -Tag 'Public' {
    Context 'When retrieving the kind of a registry value using New-MockObject' {
        # Mock the registry key object and the GetValueKind method

        It 'Should return the correct value kind (DWord) for the specified value name' {

            $mockBaseKey = New-MockObject -Type Microsoft.Win32.RegistryKey -Methods @{
                GetValueKind = { return [Microsoft.Win32.RegistryValueKind]::DWord }
            }

            # Arrange
            $mockValueName = 'TestValue'

            # Act
            $result = Get-RegistryValueKind -BaseKey $mockBaseKey -ValueName $mockValueName

            # Assert
            $result | Should -BeOfType 'Microsoft.Win32.RegistryValueKind'
            $result | Should -Be 'DWord'
        }

        It 'Should throw a SecurityException if access is denied' {
            # Arrange: Mock the behavior for a security exception
            $mockBaseKey = New-MockObject -Type Microsoft.Win32.RegistryKey -Methods @{
                GetValueKind = { throw [System.Security.SecurityException] "Access to the registry key is denied." }
            }
            $mockValueName = 'TestValue'

            # Act & Assert
            { Get-RegistryValueKind -BaseKey $mockBaseKey -ValueName $mockValueName } | Should -Throw 'Exception calling "GetValueKind" with "1" argument(s): "Access to the registry key is denied."'
        }
    }
}
