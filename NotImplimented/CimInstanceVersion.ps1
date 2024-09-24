class RegistryKeyObject
{
    [string]$Name
    [string]$Path
    [string]$ParentPath
    [RegistryValueObject[]]$Values
    [RegistryKeyObject[]]$SubKeys
    [string]$ComputerName
    [System.Management.Automation.PSCredential]$Credential

    RegistryKeyObject([string]$name, [string]$path, [string]$parentPath, [string]$computerName, [System.Management.Automation.PSCredential]$credential)
    {
        $this.Name = $name
        $this.Path = $path
        $this.ParentPath = $parentPath
        $this.Values = @()
        $this.SubKeys = @()
        $this.ComputerName = $computerName
        $this.Credential = $credential
    }

    # Method to retrieve subkeys dynamically
    [void]GetSubKeys()
    {
        $xsubKeys = Get-RegistryKey -Path $this.Path -ComputerName $this.ComputerName -Credential $this.Credential
        foreach ($subKey in $xsubKeys)
        {
            $this.SubKeys += $subKey
        }
    }

    # Method to retrieve values dynamically
    [void]GetValues()
    {
        $xvalues = Get-RegistryValue -Path $this.Path -ComputerName $this.ComputerName -Credential $this.Credential
        foreach ($value in $xvalues)
        {
            $this.Values += $value
        }
    }

    [string] ToString()
    {
        return "RegistryKeyObject: $($this.Name) (Path: $($this.Path))"
    }
}
class RegistryValueObject
{
    [string]$Name
    [string]$Path
    [string]$ParentPath
    [string]$Type = 'Value'
    [string]$ValueType
    [psobject]$Data

    RegistryValueObject([string]$name, [string]$path, [string]$parentPath, [string]$valueType, [psobject]$data)
    {
        $this.Name = $name
        $this.Path = $path
        $this.ParentPath = $parentPath
        $this.ValueType = $valueType
        $this.Data = $data
    }

    [string] ToString()
    {
        return "RegistryValueObject: $($this.Name) (Type: $($this.ValueType), Path: $($this.Path))"
    }
}
class RegistryNodeObject
{
    [string]$Name
    [string]$Path
    [RegistryKeyObject[]]$SubKeys
    [RegistryValueObject[]]$Values

    RegistryNodeObject([string]$name, [string]$path)
    {
        $this.Name = $name
        $this.Path = $path
        $this.SubKeys = @()
        $this.Values = @()
    }

    # Method to add a subkey
    [void]AddSubKey([RegistryKeyObject]$subKey)
    {
        $this.SubKeys += $subKey
    }

    # Method to add a value
    [void]AddValue([RegistryValueObject]$value)
    {
        $this.Values += $value
    }

    # Method to dynamically get subkeys and update SubKeys property
    [void]GetSubKeys([string]$computerName, [System.Management.Automation.PSCredential]$credential)
    {
        $xsubKeys = Get-RegistryKey -Path $this.Path -ComputerName $computerName -Credential $credential
        foreach ($subKey in $xsubKeys)
        {
            $this.AddSubKey($subKey)
        }
    }

    # Method to dynamically get values and update Values property
    [void]GetValues([string]$computerName, [System.Management.Automation.PSCredential]$credential)
    {
        $xvalues = Get-RegistryValue -Path $this.Path -ComputerName $computerName -Credential $credential
        foreach ($value in $xvalues)
        {
            $this.AddValue($value)
        }
    }

    [string] ToString()
    {
        return "RegistryNodeObject: $($this.Name) (Path: $($this.Path), SubKeys: $($this.SubKeys.Count), Values: $($this.Values.Count))"
    }
}

function Get-RegistryNode
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]]$Path,

        [Parameter(Position = 1, ValueFromPipelineByPropertyName = $true)]
        [string[]]$ComputerName = $env:COMPUTERNAME,

        [Parameter()]
        [System.Management.Automation.PSCredential]$Credential
    )

    begin
    {
        # Map hive names to their HKEY values
        $hiveMap = @{
            HKCR = 2147483648
            HKCU = 2147483649
            HKLM = 2147483650
            HKU  = 2147483651
            HKCC = 2147483653
        }
    }

    process
    {
        foreach ($comp in $ComputerName)
        {
            foreach ($p in $Path)
            {
                # Create a new RegistryNodeObject for each path
                $registryNode = New-Object RegistryNodeObject -ArgumentList $p, $p

                # Get Subkeys and Values for the current node
                $registryNode.GetSubKeys($comp, $Credential)
                $registryNode.GetValues($comp, $Credential)

                # Output the populated RegistryNodeObject
                $registryNode
            }
        }
    }
}

function Get-RegistryKey
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]]$Path,

        [Parameter(Position = 1, ValueFromPipelineByPropertyName = $true)]
        [string[]]$ComputerName = $env:COMPUTERNAME,

        [Parameter()]
        [System.Management.Automation.PSCredential]$Credential
    )

    begin
    {
        # Map hive names to their HKEY values
        $hiveMap = @{
            HKCR = 2147483648
            HKCU = 2147483649
            HKLM = 2147483650
            HKU  = 2147483651
            HKCC = 2147483653
        }
    }

    process
    {
        foreach ($comp in $ComputerName)
        {
            foreach ($p in $Path)
            {
                $parsedPath = Parse-RegistryPath -RegistryPath $p
                $hive = $parsedPath.Hive
                $subKey = $parsedPath.SubKey

                $enumKeyResult = Invoke-CimMethod -Namespace 'root/default' `
                    -ClassName 'StdRegProv' `
                    -MethodName 'EnumKey' `
                    -Arguments @{
                    hDefKey     = [UInt32]$hiveMap[$hive]
                    sSubKeyName = $subKey
                }

                if ($enumKeyResult.ReturnValue -eq 0)
                {
                    foreach ($subKeyName in $enumKeyResult.sNames)
                    {
                        $keyObject = [RegistryKeyObject]::new(
                            $subKeyName,
                            "Registry::$hive\$subKey\$subKeyName",
                            "Registry::$hive\$subKey",
                            $comp,
                            $Credential
                        )
                        $keyObject
                    }
                }
                else
                {
                    Write-Error "Failed to enumerate subkeys on $comp."
                }
            }
        }
    }
}

function Get-RegistryValue
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]]$Path,

        [Parameter(Position = 1, ValueFromPipelineByPropertyName = $true)]
        [string[]]$ComputerName = $env:COMPUTERNAME,

        [Parameter()]
        [System.Management.Automation.PSCredential]$Credential
    )

    begin
    {
        # Map hive names to their HKEY values
        $hiveMap = @{
            HKCR = 2147483648
            HKCU = 2147483649
            HKLM = 2147483650
            HKU  = 2147483651
            HKCC = 2147483653
        }
    }

    process
    {
        foreach ($comp in $ComputerName)
        {
            foreach ($p in $Path)
            {
                $parsedPath = Parse-RegistryPath -RegistryPath $p
                $hive = $parsedPath.Hive
                $subKey = $parsedPath.SubKey

                $enumValuesResult = Invoke-CimMethod -Namespace 'root/default' `
                    -ClassName 'StdRegProv' `
                    -MethodName 'EnumValues' `
                    -Arguments @{
                    hDefKey     = [UInt32]$hiveMap[$hive]
                    sSubKeyName = $subKey
                }

                if ($enumValuesResult.ReturnValue -eq 0)
                {
                    $valueNames = $enumValuesResult.sNames
                    $valueTypes = $enumValuesResult.Types

                    for ($i = 0; $i -lt $valueNames.Count; $i++)
                    {
                        $valueName = $valueNames[$i]
                        $valueType = $valueTypes[$i]
                        $valueData = $null

                        # Retrieve the value data
                        switch ($valueType)
                        {
                            1
                            {
                                # REG_SZ
                                $readValue = Invoke-CimMethod -Namespace 'root/default' `
                                    -ClassName 'StdRegProv' `
                                    -MethodName 'GetStringValue' `
                                    -Arguments @{
                                    hDefKey     = [UInt32]$hiveMap[$hive]
                                    sSubKeyName = $subKey
                                    sValueName  = $valueName
                                }
                                $valueData = $readValue.sValue
                            }
                            3
                            {
                                # REG_BINARY
                                $readValue = Invoke-CimMethod -Namespace 'root/default' `
                                    -ClassName 'StdRegProv' `
                                    -MethodName 'GetBinaryValue' `
                                    -Arguments @{
                                    hDefKey     = [UInt32]$hiveMap[$hive]
                                    sSubKeyName = $subKey
                                    sValueName  = $valueName
                                }
                                $valueData = $readValue.uValue
                            }
                            4
                            {
                                # REG_DWORD
                                $readValue = Invoke-CimMethod -Namespace 'root/default' `
                                    -ClassName 'StdRegProv' `
                                    -MethodName 'GetDWORDValue' `
                                    -Arguments @{
                                    hDefKey     = [UInt32]$hiveMap[$hive]
                                    sSubKeyName = $subKey
                                    sValueName  = $valueName
                                }
                                $valueData = $readValue.uValue
                            }
                            7
                            {
                                # REG_MULTI_SZ
                                $readValue = Invoke-CimMethod -Namespace 'root/default' `
                                    -ClassName 'StdRegProv' `
                                    -MethodName 'GetMultiStringValue' `
                                    -Arguments @{
                                    hDefKey     = [UInt32]$hiveMap[$hive]
                                    sSubKeyName = $subKey
                                    sValueName  = $valueName
                                }
                                $valueData = $readValue.sValue
                            }
                            11
                            {
                                # REG_QWORD
                                $readValue = Invoke-CimMethod -Namespace 'root/default' `
                                    -ClassName 'StdRegProv' `
                                    -MethodName 'GetQWORDValue' `
                                    -Arguments @{
                                    hDefKey     = [UInt32]$hiveMap[$hive]
                                    sSubKeyName = $subKey
                                    sValueName  = $valueName
                                }
                                $valueData = $readValue.uValue
                            }
                        }

                        # Return the RegistryValueObject for each value
                        [RegistryValueObject]::new(
                            $valueName,
                            "Registry::$hive\$subKey",
                            "Registry::$hive\$subKey",
                            $valueType,
                            $valueData
                        )
                    }
                }
                else
                {
                    Write-Error "Failed to enumerate values on $comp."
                }
            }
        }
    }
}


function Parse-RegistryPath
{
    param (
        [string]$RegistryPath
    )
    if ($RegistryPath -match '^Registry::(?<Hive>HKLM|HKCU|HKCR|HKU|HKCC)\\(?<SubKey>.+)')
    {
        return @{
            Hive   = $matches.Hive
            SubKey = $matches.SubKey
        }
    }
    else
    {
        throw "Invalid registry path format: $RegistryPath. Expected format is 'Registry::HKLM\SubKey'."
    }
}

function Process-RegistryKey
{
    param (
        [string]$ComputerName,
        [string]$Path,
        [System.Management.Automation.PSCredential]$Credential
    )

    $parsedPath = Parse-RegistryPath -RegistryPath $Path
    $hive = $parsedPath.Hive
    $subKey = $parsedPath.SubKey
    $hDefKey = $hiveMap[$hive]

    try
    {
        $sessionOptions = New-CimSessionOption -Protocol 'Wsman'
        $sessionParams = @{
            ComputerName  = $ComputerName
            Credential    = $Credential
            SessionOption = $sessionOptions
        }
        $session = New-CimSession @sessionParams

        # Retrieve Subkeys
        $enumKeyResult = Invoke-CimMethod -CimSession $session `
            -Namespace 'root/default' `
            -ClassName 'StdRegProv' `
            -MethodName 'EnumKey' `
            -Arguments @{
            hDefKey     = [UInt32]$hDefKey
            sSubKeyName = $subKey
        }

        if ($enumKeyResult.ReturnValue -eq 0)
        {
            foreach ($subKeyName in $enumKeyResult.sNames)
            {
                [RegistryKeyObject]::new(
                    $subKeyName,
                    "Registry::$hive\$subKey\$subKeyName",
                    "Registry::$hive\$subKey"
                )
            }
        }
        else
        {
            Write-Error "Failed to enumerate subkeys on $ComputerName. ReturnValue: $($enumKeyResult.ReturnValue)"
        }
    }
    catch
    {
        Write-Error "Failed to enumerate registry keys on $ComputerName`: $_"
    }
    finally
    {
        if ($session)
        {
            Remove-CimSession -CimSession $session
        }
    }
}
function Process-RegistryValue
{
    param (
        [string]$ComputerName,
        [string]$Path,
        [System.Management.Automation.PSCredential]$Credential
    )

    $parsedPath = Parse-RegistryPath -RegistryPath $Path
    $hive = $parsedPath.Hive
    $subKey = $parsedPath.SubKey
    $hDefKey = $hiveMap[$hive]

    try
    {
        $sessionOptions = New-CimSessionOption -Protocol 'Wsman'
        $sessionParams = @{
            ComputerName  = $ComputerName
            Credential    = $Credential
            SessionOption = $sessionOptions
        }
        $session = New-CimSession @sessionParams

        # Retrieve values
        $enumValuesResult = Invoke-CimMethod -CimSession $session `
            -Namespace 'root/default' `
            -ClassName 'StdRegProv' `
            -MethodName 'EnumValues' `
            -Arguments @{
            hDefKey     = [UInt32]$hDefKey
            sSubKeyName = $subKey
        }

        if ($enumValuesResult.ReturnValue -eq 0)
        {
            $valueNames = $enumValuesResult.sNames
            $valueTypes = $enumValuesResult.Types

            for ($i = 0; $i -lt $valueNames.Count; $i++)
            {
                $valueName = $valueNames[$i]
                $valueType = $valueTypes[$i]
                $valueData = $null

                # Read the value based on its type
                switch ($valueType)
                {
                    1
                    {
                        # REG_SZ
                        $readValue = Invoke-CimMethod -CimSession $session `
                            -Namespace 'root/default' `
                            -ClassName 'StdRegProv' `
                            -MethodName 'GetStringValue' `
                            -Arguments @{
                            hDefKey     = [UInt32]$hDefKey
                            sSubKeyName = $subKey
                            sValueName  = $valueName
                        }
                        $valueData = $readValue.sValue
                    }
                    3
                    {
                        # REG_BINARY
                        $readValue = Invoke-CimMethod -CimSession $session `
                            -Namespace 'root/default' `
                            -ClassName 'StdRegProv' `
                            -MethodName 'GetBinaryValue' `
                            -Arguments @{
                            hDefKey     = [UInt32]$hDefKey
                            sSubKeyName = $subKey
                            sValueName  = $valueName
                        }
                        $valueData = $readValue.uValue
                    }
                    4
                    {
                        # REG_DWORD
                        $readValue = Invoke-CimMethod -CimSession $session `
                            -Namespace 'root/default' `
                            -ClassName 'StdRegProv' `
                            -MethodName 'GetDWORDValue' `
                            -Arguments @{
                            hDefKey     = [UInt32]$hDefKey
                            sSubKeyName = $subKey
                            sValueName  = $valueName
                        }
                        $valueData = $readValue.uValue
                    }
                    7
                    {
                        # REG_MULTI_SZ
                        $readValue = Invoke-CimMethod -CimSession $session `
                            -Namespace 'root/default' `
                            -ClassName 'StdRegProv' `
                            -MethodName 'GetMultiStringValue' `
                            -Arguments @{
                            hDefKey     = [UInt32]$hDefKey
                            sSubKeyName = $subKey
                            sValueName  = $valueName
                        }
                        $valueData = $readValue.sValue
                    }
                    11
                    {
                        # REG_QWORD
                        $readValue = Invoke-CimMethod -CimSession $session `
                            -Namespace 'root/default' `
                            -ClassName 'StdRegProv' `
                            -MethodName 'GetQWORDValue' `
                            -Arguments @{
                            hDefKey     = [UInt32]$hDefKey
                            sSubKeyName = $subKey
                            sValueName  = $valueName
                        }
                        $valueData = $readValue.uValue
                    }
                    Default
                    {
                        # Other types not handled explicitly
                        $valueData = $null
                    }
                }

                # Return a new RegistryValueObject for each value
                [RegistryValueObject]::new(
                    $valueName,
                    "Registry::$hive\$subKey",
                    "Registry::$hive\$subKey",
                    $valueType,
                    $valueData
                )
            }
        }
        else
        {
            Write-Error "Failed to enumerate values on $ComputerName. ReturnValue: $($enumValuesResult.ReturnValue)"
        }
    }
    catch
    {
        Write-Error "Failed to retrieve registry values on $ComputerName`: $_"
    }
    finally
    {
        if ($session)
        {
            Remove-CimSession -CimSession $session
        }
    }
}


#$node = Get-RegistryNode -Path "Registry::HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
