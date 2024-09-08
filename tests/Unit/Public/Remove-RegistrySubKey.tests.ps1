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

   # Test for successfully removing a subkey
   It 'should remove an existing subkey' {
    # Mock the parent registry key object and its DeleteSubKeyTree method
    $mockParentKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
        DeleteSubKeyTree = { param($SubKeyName) return $null }
    }

    # Call the function to remove an existing subkey
    {Remove-RegistrySubKey -ParentKey $mockParentKey -SubKeyName 'ExistingSubKey' -confirm:$false} | Should -Be $true

}

    # Test for non-existent subkey
    It 'should return $false and write an error if the subkey does not exist' {
        # Mock the parent registry key object and its DeleteSubKeyTree method to throw an error
        $mockParentKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
            DeleteSubKeyTree = { param($SubKeyName) throw "Subkey does not exist" }
        }

        # Call the function to remove a non-existent subkey with -Confirm:$false
        $result = Remove-RegistrySubKey -ParentKey $mockParentKey -SubKeyName 'NonExistentSubKey' -Confirm:$false

        # Validate that $false is returned
        $result | Should -Be $false
    }

    # Test for handling errors when deleting the subkey
    It 'should handle exceptions and return $false when an error occurs' {
        # Mock the parent registry key object and its DeleteSubKeyTree method to throw an exception
        $mockParentKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
            DeleteSubKeyTree = { throw [Exception]::new("Unexpected error") }
        }

        # Call the function to remove a subkey that causes an exception with -Confirm:$false
        $result = Remove-RegistrySubKey -ParentKey $mockParentKey -SubKeyName 'FaultySubKey' -Confirm:$false

        # Validate that $false is returned
        $result | Should -Be $false
    }

    # Test for confirming the operation with ShouldProcess
    It 'should not remove the subkey if ShouldProcess returns $false' {
        # Mock the parent registry key object and its DeleteSubKeyTree method
        $mockParentKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
            DeleteSubKeyTree = { param($SubKeyName) return $null }
        }

        # Call the function with -WhatIf to simulate ShouldProcess returning false
        $result = Remove-RegistrySubKey -ParentKey $mockParentKey -SubKeyName 'ExistingSubKey' -WhatIf -Confirm:$false

        # Validate that the subkey was not removed (returns $null)
        $result | Should -Be $false
    }
}
