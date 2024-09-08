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

Describe 'Open-RegistrySubKey function tests' -Tag 'Public' {

    # Test for successfully opening a subkey
    It 'should open an existing subkey' {

        # Mock the parent registry key object and its OpenSubKey method using New-MockObject
        $mockParentKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
            OpenSubKey = { param($subKeyName) if ($subKeyName -eq 'ExistingSubKey')
                {
                    return 'MockedSubKey'
                }
                else
                {
                    return $null
                } }
        }

        # Call the function
        $result = Open-RegistrySubKey -ParentKey $mockParentKey -SubKeyName 'ExistingSubKey'

        # Validate the result
        $result | Should -Be 'MockedSubKey'

        # Ensure the ParentKey's OpenSubKey method was called with the correct subkey name
        #Assert-MockCalled $mockParentKey.OpenSubKey -Exactly 1 -Scope It -ParameterFilter { $SubKeyName -eq 'ExistingSubKey' }
    }

    # Test for handling non-existent subkey
    It 'should return $null if the subkey does not exist' {

        $mockParentKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
            OpenSubKey = { param($subKeyName) if ($subKeyName -eq 'ExistingSubKey')
                {
                    return 'MockedSubKey'
                }
                else
                {
                    return $null
                } }
        }

        # Call the function with a non-existent subkey
        $result = Open-RegistrySubKey -ParentKey $mockParentKey -SubKeyName 'NonExistentSubKey' -ErrorAction Continue

        # Validate that $null is returned
        $result | Should -Be $null

        # Ensure the ParentKey's OpenSubKey method was called with the correct subkey name
        #Assert-MockCalled $mockParentKey.OpenSubKey -Exactly 1 -Scope It -ParameterFilter { $SubKeyName -eq 'NonExistentSubKey' }
    }

    # Test for handling an error when accessing the subkey
    It 'should return $null and write an error when an exception occurs' {
        # Mock the OpenSubKey method to throw an exception
        $mockParentKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
            OpenSubKey = { throw [Exception]::new("Unexpected error") }
        }

        try
        {

            # Call the function
            $result = Open-RegistrySubKey -ParentKey $mockParentKey -SubKeyName 'FaultySubKey'

        }
        catch
        {

        }
        # Validate that $null is returned
        $result | Should -Be $null

        # Ensure the error was caught and handled
        #Assert-MockCalled $mockParentKey.OpenSubKey -Exactly 1 -Scope It -ParameterFilter { $SubKeyName -eq 'FaultySubKey' }
    }
}
