BeforeAll {
    $script:dscModuleName = "WinRegOps"

    Import-Module -Name $script:dscModuleName

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName

    $helperPath = "$PSScriptRoot/../../Helpers/Log-TestDetails.ps1"
    . $helperPath
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

Describe 'Get-RegistryValue function tests' -Tag 'Public' {

    # Test for successfully retrieving a value from the registry
    It 'should retrieve the specified value from the registry' {
        # Mock the RegistryKey object and the GetValue method to simulate a successful retrieval
        $mockKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
            GetValue = { param($ValueName) if ($ValueName -eq 'Setting')
                {
                    return 'Value123'
                }
                else
                {
                    return $null
                } }
        }

        # Call the function
        $result = Get-RegistryValue -Key $mockKey -ValueName 'Setting'

        # Validate the result
        $result | Should -Be 'Value123'
    }

    # Test when the value is not found in the registry
    It 'should return $null if the specified value is not found in the registry' {
        # Mock the RegistryKey object and the GetValue method to simulate a missing value
        $mockKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
            GetValue = { param($ValueName) return $null }
        }

        # Call the function
        $result = Get-RegistryValue -Key $mockKey -ValueName 'NonExistentValue' -ErrorAction Continue

        # Validate that $null is returned
        $result | Should -Be $null
    }



    # Test when an error occurs while retrieving the value
    It 'should handle errors and return $null when an exception is thrown' {
        # Mock the RegistryKey object to throw an error when GetValue is called
        $mockKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
            GetValue = { throw [Exception]::new("Registry read error") }
        }

        # Call the function
        $result = Get-RegistryValue -Key $mockKey -ValueName 'Setting' -ErrorAction Continue

        # Log details for debugging
        Log-TestDetails -TestName 'should handle errors and return $null when an exception is thrown' `
            -Details $result `
            -AdditionalInfo 'Key: $mockKey, ValueName: Setting'

        # Validate that $null is returned and an error was written
        $result | Should -Be $null
    }

    # Test that verbose message is written when value is not found
    It 'should write a verbose message if the value is not found' {
        # Mock the RegistryKey object to simulate a missing value
        $mockKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
            GetValue = { param($ValueName) return $null }
        }

        # Mock Write-Verbose to capture the verbose message
        Mock Write-Verbose

        # Call the function with the -Verbose switch
        Get-RegistryValue -Key $mockKey -ValueName 'NonExistentValue' -Verbose -ErrorAction Continue

        # Verify that Write-Verbose was called with the correct message
        Assert-MockCalled Write-Verbose -Exactly 1 -Scope It -ParameterFilter {
            $Message -eq 'NonExistentValue not found in the registry key.'
        }
    }

}
