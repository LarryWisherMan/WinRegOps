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


Describe 'Remove-RegistrySubKey Integration Tests using TestRegistry' -Tag 'Integration' {

    AfterEach {
        Remove-Item -Path TestRegistry:\ -Recurse -ErrorAction SilentlyContinue
    }

    It 'Should remove the subkey successfully when given valid inputs' {

        $path = New-Item -Path TestRegistry:\ -Name TestLocation

        $registryPath = ($path -split "HKEY_CURRENT_USER\\")

        $testRegistryPath = (New-Item -Path "TestRegistry:\TestLocation" -Name TestSubKey).pspath

        # Arrange
        $registryHive = [Microsoft.Win32.RegistryHive]::CurrentUser

        $regPath = $registryPath[1] + "\TestSubKey"

        # Act
        Remove-RegistrySubKey -RegistryHive $registryHive -RegistryPath $RegPath -Confirm:$false

        # Assert
        Test-Path "TestRegistry:\TestLocation\TestSubKey" | Should -BeFalse
    }

    It 'Should throw an error if the subkey does not exist' {
        # Arrange
        $registryHive = [Microsoft.Win32.RegistryHive]::CurrentUser
        $invalidSubKey = "NonExistentSubKey"

        # Act & Assert
        { Remove-RegistrySubKey -RegistryHive $registryHive -RegistryPath "Software\Pester\$invalidSubKey" -Confirm:$false } | Should -Throw
    }

    It 'Should support the ByKey parameter set' {

        Remove-Item -Path TestRegistry:\TestLocation -Recurse -ErrorAction SilentlyContinue
        $path = New-Item -Path TestRegistry:\ -Name TestLocation
        $registryPath = ($path -split "HKEY_CURRENT_USER\\")
        $testRegistryPath = (New-Item -Path "TestRegistry:\TestLocation" -Name TestSubKey).pspath

        # Arrange
        $parentKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($registryPath[1], $true)
        $subKeyName = "TestSubKey"

        # Act
        Remove-RegistrySubKey -ParentKey $parentKey -SubKeyName $subKeyName -Confirm:$false

        # Assert
        Test-Path "TestRegistry:\TestLocation\TestSubKey" | Should -BeFalse

    }

    It 'Should not remove subkey if ShouldProcess returns false' {
        # Arrange
        $registryHive = [Microsoft.Win32.RegistryHive]::CurrentUser

        Remove-Item -Path TestRegistry:\TestLocation -Recurse -ErrorAction SilentlyContinue
        $path = New-Item -Path TestRegistry:\ -Name TestLocation
        $testRegistryPath = (New-Item -Path "TestRegistry:\TestLocation" -Name TestSubKey).pspath

        $registryPath = ($path -split "HKEY_CURRENT_USER\\")


        Mock Invoke-DeleteSubKey -ParameterFilter {
            $PSCmdlet.ShouldProcess($registryPath[1], 'Removing registry subkey') -eq $false
        } -ModuleName $script:dscModuleName

        # Act
        Remove-RegistrySubKey -RegistryHive $registryHive -RegistryPath $registryPath[1] -Confirm:$false -WhatIf

        # Assert
        Test-Path "TestRegistry:\TestLocation\TestSubKey" | Should -BeTrue

        Assert-MockCalled -CommandName Invoke-DeleteSubKey -Exactly 0 -Scope It -ModuleName $script:dscModuleName

    }

    It 'Should handle non-writable registry keys gracefully' {
        # Arrange
        $parentKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey("Software\Pester\" + (Split-Path (Test-Path TestRegistry:\) -Leaf) + "\TestLocation", $false)
        $subKeyName = "TestSubKey"

        # Act & Assert
        { Remove-RegistrySubKey -ParentKey $parentKey -SubKeyName $subKeyName -Confirm:$false } | Should -Throw
    }
}
