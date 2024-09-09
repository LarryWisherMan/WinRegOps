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
        $result = Get-RegistryValue -Key $mockKey -ValueName 'Setting' -ErrorAction SilentlyContinue

        # Validate that $null is returned
        $result | Should -Be $null

        write-host $error[0].Exception.Message

        $exception = @"
Failed to retrieve value 'Setting'. Error: Exception calling "GetValue" with "2" argument(s): "Registry read error"
"@
        # Ensure the error contains the expected core message
        $error[0].Exception.Message | Should -Be $exception

        # Validate that $null is returned and an error was written
        $result | Should -Be $null
    }

}
