function Get-InstalledApplications
{
    param (
        [string]$AppName = "*", # The name of the application to filter
        [string]$Vendor, # Optional: The vendor of the application to filter
        [string]$ComputerName = $env:ComputerName
    )

    # Define the registry paths for installed applications
    $registryPaths = @(
        "Software\Microsoft\Windows\CurrentVersion\Uninstall",
        "Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    )

    $AppList = @()

    # Only get relevant registry values for each application
    $requiredProperties = @("DisplayName", "Publisher", "DisplayVersion", "UninstallString", "InstallDate")

    # Iterate over each registry path (64-bit and 32-bit locations)
    foreach ($registryPath in $registryPaths)
    {
        try
        {
            # Open the registry key for each path
            $RegistryKey = Open-RegistryKey -RegistryHive LocalMachine -RegistryPath $registryPath -ComputerName $ComputerName

            # Retrieve all subkey names (representing installed applications)
            $SubKeys = $RegistryKey.GetSubKeyNames()

            # Iterate through each subkey (application)
            foreach ($SubkeyName in $SubKeys)
            {
                # Open the subkey and only retrieve relevant values
                $selectedKey = Get-RegistrySubKey -BaseKey $RegistryKey -Name $SubkeyName -writable $false

                try
                {
                    # Create a custom object with only necessary values
                    $app = [pscustomobject]@{
                        DisplayName     = $null
                        Publisher       = $null
                        DisplayVersion  = $null
                        UninstallString = $null
                        InstallDate     = $null
                    }

                    foreach ($property in $requiredProperties)
                    {
                        $value = Get-RegistryValue -BaseKey $selectedKey -ValueName $property
                        if ($value)
                        {
                            if ($property -eq 'InstallDate' -and $value -match '^\d{8}$')
                            {
                                # Convert InstallDate (YYYYMMDD) to a formatted date
                                $app.InstallDate = [datetime]::ParseExact($value, 'yyyyMMdd', $null).ToString('yyyy-MM-dd')
                            }
                            else
                            {
                                $app.$property = $value
                            }
                        }
                    }

                    # Only add the application if DisplayName is present and matches the filter
                    if ($app.DisplayName -and $app.DisplayName -like $AppName)
                    {
                        if (!$Vendor -or $app.Publisher -like $Vendor)
                        {
                            $AppList += $app
                        }
                    }
                }
                finally
                {
                    # Dispose of the selected subkey
                    if ($selectedKey)
                    {
                        $selectedKey.Dispose() 
                    }
                }
            }
        }
        finally
        {
            # Dispose of the registry key
            if ($RegistryKey)
            {
                $RegistryKey.Dispose() 
            }
        }
    }

    return $AppList
}
