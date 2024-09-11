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

Describe 'Open-RegistryKey function tests' -Tag 'Public' {

    BeforeEach {
        # Mock the helper functions that abstract static methods
        Mock Get-OpenBaseKey {
            $mockRegistryKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
                OpenSubKey = { param($path, $writable) if ($path -eq 'Software\MyApp')
                    {
                        return 'MockedRegistryKey'
                    }
                    else
                    {
                        return $null
                    } }
            }
            return $mockRegistryKey
        }

        Mock Get-OpenRemoteBaseKey {
            $mockRegistryKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
                OpenSubKey = { param($path, $writable) if ($path -eq 'Software\MyApp')
                    {
                        return 'MockedRemoteRegistryKey'
                    }
                    else
                    {
                        return $null
                    } }
            }
            return $mockRegistryKey
        }
    }

    # Test for opening a local registry key successfully
    It 'should open a local registry key' {
        # Call the function
        $result = Open-RegistryKey -RegistryPath 'Software\MyApp'

        # Validate the result
        $result | Should -Be 'MockedRegistryKey'

        # Ensure Get-OpenBaseKey was called
        Assert-MockCalled Get-OpenBaseKey -Exactly 1 -Scope It
    }

    # Test for handling non-existent local registry key
    It 'should return $null if the local registry key does not exist' {
        # Mock the return value of the registry subkey being non-existent
        Mock Get-OpenBaseKey {
            $mockRegistryKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
                OpenSubKey = { param($path, $writable) return $null }
            }
            return $mockRegistryKey
        }

        # Call the function
        $result = Open-RegistryKey -RegistryPath 'Software\NonExistentKey' -ErrorAction Continue

        # Validate that $null is returned
        $result | Should -Be $null

        # Ensure Get-OpenBaseKey was called
        Assert-MockCalled Get-OpenBaseKey -Exactly 1 -Scope It
    }

    # Test for opening a registry key on a remote computer
    It 'should open a remote registry key' {
        # Call the function for a remote registry key
        $result = Open-RegistryKey -RegistryPath 'Software\MyApp' -ComputerName 'RemotePC'

        # Validate the result
        $result | Should -Be 'MockedRemoteRegistryKey'

        # Ensure Get-OpenRemoteBaseKey was called
        Assert-MockCalled Get-OpenRemoteBaseKey -Exactly 1 -Scope It
    }

    # Test for handling access denied
    # Test for handling access denied
    It 'should return $null and write an error if access is denied' {
        # Mock access denied exception
        Mock -ModuleName $Script:dscModuleName -CommandName Get-OpenBaseKey { throw [System.Security.SecurityException]::new("Access Denied") }

        # Call the function
        $result = Open-RegistryKey -RegistryPath 'Software\MyApp' -ErrorAction Continue

        # Validate that $null is returned
        $result | Should -Be $null

        # Ensure the error was thrown and caught correctly
        Assert-MockCalled Get-OpenBaseKey -Exactly 1 -Scope It


    }

    # Test for generic failure when opening the registry key
    It 'should return $null and write an error on failure' {
        # Mock a generic failure
        Mock -ModuleName $Script:dscModuleName -CommandName Get-OpenBaseKey { throw [Exception]::new("Unexpected error") }

        # Call the function
        $result = Open-RegistryKey -RegistryPath 'Software\MyApp' -ErrorAction Continue

        # Validate that $null is returned
        $result | Should -Be $null

        # Ensure the error was thrown and caught correctly
        Assert-MockCalled Get-OpenBaseKey -Exactly 1 -Scope It

        # Check that the correct error message was written

    }

}
