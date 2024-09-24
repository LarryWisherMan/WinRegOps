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

        Mock Open-RegistrySubKey {
            param ($BaseKey, $Name, $Writable)
            if ($Name -eq 'Software\MyApp')
            {
                return 'MockedSubKey'
            }
            else
            {
                return $null
            }
        }
    }

    # Test for opening a local registry key successfully
    It 'should open a local registry key' {
        # Call the function
        $result = Open-RegistryKey -RegistryPath 'Software\MyApp'

        # Validate the result
        $result | Should -Be 'MockedSubKey'

        # Ensure Get-OpenBaseKey was called
        Assert-MockCalled Get-OpenBaseKey -Exactly 1 -Scope It
        Assert-MockCalled Open-RegistrySubKey -Exactly 1 -Scope It
    }

    # Test for handling non-existent local registry key
    It 'should return $null if the local registry key does not exist' {
        # Mock the return value of the registry subkey being non-existent
        Mock Open-RegistrySubKey {
            param ($BaseKey, $Name, $Writable) return $null
        }

        # Call the function
        $result = Open-RegistryKey -RegistryPath 'Software\NonExistentKey' -ErrorAction Continue

        # Validate that $null is returned
        $result | Should -Be $null

        # Ensure Get-OpenBaseKey was called
        Assert-MockCalled Get-OpenBaseKey -Exactly 1 -Scope It
        Assert-MockCalled Open-RegistrySubKey -Exactly 1 -Scope It
    }

    # Test for opening a registry key on a remote computer
    It 'should open a remote registry key' {
        # Call the function for a remote registry key
        $result = Open-RegistryKey -RegistryPath 'Software\MyApp' -ComputerName 'RemotePC'

        # Validate the result
        $result | Should -Be 'MockedSubKey'

        # Ensure Get-OpenRemoteBaseKey was called
        Assert-MockCalled Get-OpenRemoteBaseKey -Exactly 1 -Scope It
        Assert-MockCalled Open-RegistrySubKey -Exactly 1 -Scope It
    }

    # Test for handling access denied
    It 'should return $null and write an error if access is denied' {
        # Mock access denied exception
        Mock Get-OpenBaseKey { throw [System.Security.SecurityException]::new("Access Denied") }

        # Call the function
        { Open-RegistryKey -RegistryPath 'Software\MyApp' } | should -throw

        # Ensure the error was thrown and caught correctly
        Assert-MockCalled Get-OpenBaseKey -Exactly 1 -Scope It
    }

    # Test for generic failure when opening the registry key
    It 'should return $null and write an error on failure' {
        # Mock a generic failure
        Mock Get-OpenBaseKey { throw [Exception]::new("Unexpected error") }

        # Call the function
        $result = Open-RegistryKey -RegistryPath 'Software\MyApp' -ErrorAction Continue

        # Validate that $null is returned
        $result | Should -Be $null

        # Ensure the error was thrown and caught correctly
        Assert-MockCalled Get-OpenBaseKey -Exactly 1 -Scope It

        # Check that the correct error message was written
        $message = @"
Failed to open registry hive 'LocalMachine' on '$($env:Computername)'. Error: Unexpected error
"@

        $errorRecord = $error[0].Exception.Message
        $errorRecord | Should -Be $message
    }

    # Edge case test: No RegistryPath provided (should return base key)
    It 'should return base registry key when no RegistryPath is provided' {

        InModuleScope -ScriptBlock {
            # Mock a valid, non-disposed RegistryKey object


            Mock Get-OpenBaseKey {
                $mockRegistryKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Properties @{
                    name = 'HKEY_LOCAL_MACHINE'

                } -Methods @{
                    GetSubKeyNames = { return @('Software') }
                    Dispose        = { }
                }
                return $mockRegistryKey
            }

            Mock Open-RegistrySubKey {
                param ($BaseKey, $Name, $Writable) return 'MockedSubKey'
            }

        }

        # Call the function without providing RegistryPath
        $result = Open-RegistryKey

        $result.NAme | Should -Be 'HKEY_LOCAL_MACHINE'

        # Ensure Get-OpenBaseKey was called (local machine by default)
        Assert-MockCalled Get-OpenBaseKey -Exactly 1 -Scope It

        Assert-MockCalled Open-RegistrySubKey -Exactly 0 -Scope It

        # Ensure Open-RegistrySubKey was NOT called since no path was provided
    }


}
