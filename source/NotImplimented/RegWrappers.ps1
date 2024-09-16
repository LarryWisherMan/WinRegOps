function Get-DynamicParametersFromMethod
{
    param (
        [Type]$ClassType, # The .NET type of the class, e.g., [Microsoft.Win32.RegistryKey]
        [string]$MethodName          # The method name to generate parameters for, e.g., "OpenSubKey"
    )

    # Create dynamic parameters dictionary
    $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

    # Retrieve methods for the given method name
    $methods = $ClassType.GetMethods() | Where-Object { $_.Name -eq $MethodName }

    foreach ($method in $methods)
    {
        $parameterSetName = $method.ToString()  # Using the method signature as the parameter set name

        # Get parameters for each method overload
        $parameters = $method.GetParameters()

        foreach ($parameter in $parameters)
        {
            # Check if the parameter already exists to avoid duplicates
            if (-not $paramDictionary.ContainsKey($parameter.Name))
            {
                # Create a dynamic parameter for each method parameter
                $runtimeParam = New-Object System.Management.Automation.RuntimeDefinedParameter(
                    $parameter.Name, # Parameter name
                    $parameter.ParameterType, # Type of the parameter
                    [System.Management.Automation.ParameterAttribute]@{
                        Mandatory        = $true
                        ParameterSetName = $parameterSetName   # Bind this parameter to the method overload (parameter set)
                    }
                )
                # Add dynamic parameter to dictionary
                $paramDictionary.Add($parameter.Name, $runtimeParam)
            }
            else
            {
                # If parameter exists, just add it to the new parameter set (for overloads)
                $existingParam = $paramDictionary[$parameter.Name]
                $paramAttr = New-Object System.Management.Automation.ParameterAttribute
                $paramAttr.ParameterSetName = $parameterSetName
                $existingParam.Attributes.Add($paramAttr)
            }
        }
    }

    return $paramDictionary
}
function Invoke-MethodOverloadFromBoundParam
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ParameterSetName, # The full parameter set name (e.g., "Microsoft.Win32.RegistryKey OpenSubKey(System.String, Boolean)")

        [Parameter(Mandatory = $true)]
        [hashtable]$Parameters, # The bound parameters (e.g., @{BaseKey = $BaseKey; Name = $Name; writable = $writable})

        [Parameter(Mandatory = $true)]
        [object]$TargetInstance             # The instance of the class to invoke the method on (e.g., the BaseKey)
    )

    # Parse the method name from the parameter set (e.g., "OpenSubKey")
    $MethodName = ($ParameterSetName -split ' ')[1]
    $methodName = ($MethodName -split '\(')[0]

    # Build the list of argument types and arguments based on the bound parameters
    $ArgumentTypes = @()
    $Arguments = @()

    # Loop over the bound parameters and match them to the expected types
    foreach ($param in $Parameters.Keys)
    {
        if ($param -ne 'BaseKey')
        {
            # Ignore BaseKey, it's the target instance
            $Arguments += $Parameters[$param]
            $ArgumentTypes += $Parameters[$param].GetType()  # Get the actual CLR type of each argument
        }
    }

    # Retrieve the method with the correct BindingFlags (Instance method)
    $Method = $TargetInstance.GetType().GetMethod($MethodName, [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::Public, $null, $ArgumentTypes, $null)

    if (-not $Method)
    {
        throw "No method found with signature '$ParameterSetName'."
    }

    # Invoke the method dynamically on the target instance with the arguments
    return $Method.Invoke($TargetInstance, $Arguments)
}
function Add-DynamicParameter
{
    param (
        [System.Management.Automation.RuntimeDefinedParameterDictionary]$ParamDictionary,
        [string[]]$ParameterSetNames,
        [string]$ParameterName, # Name of the parameter (e.g., 'BaseKey')
        [Type]$ParameterType = [Microsoft.Win32.RegistryKey], # Type of the parameter (e.g., [Microsoft.Win32.RegistryKey])
        [bool]$IsMandatory = $true                            # Whether the parameter is mandatory (default is $true)
    )

    # Define the dynamic parameter attributes
    $parameterAttributes = New-Object System.Collections.ObjectModel.Collection[System.Attribute]

    $paramAttr = New-Object System.Management.Automation.ParameterAttribute
    $paramAttr.Mandatory = $IsMandatory  # Set whether the parameter is mandatory
    $parameterAttributes.Add($paramAttr)

    $dynamicParam = New-Object System.Management.Automation.RuntimeDefinedParameter(
        $ParameterName, # Parameter name
        $ParameterType, # Parameter type (e.g., [Microsoft.Win32.RegistryKey])
        $parameterAttributes            # Parameter attributes
    )

    # Add the dynamic parameter to the dictionary if it doesn't already exist
    if (-not $ParamDictionary.ContainsKey($ParameterName))
    {
        $ParamDictionary.Add($ParameterName, $dynamicParam)
    }

    # Ensure the parameter is added to each parameter set
    foreach ($parameterSetName in $ParameterSetNames)
    {
        $paramAttrClone = New-Object System.Management.Automation.ParameterAttribute
        $paramAttrClone.Mandatory = $IsMandatory
        $paramAttrClone.ParameterSetName = $parameterSetName
        $ParamDictionary[$ParameterName].Attributes.Add($paramAttrClone)
    }

    return $ParamDictionary
}
function Get-RegistryBaseKey
{
    [CmdletBinding()]
    param (

    )

    DynamicParam
    {
        # Get dynamic parameters for the OpenBaseKey method
        Get-DynamicParametersFromMethod -ClassType ([Microsoft.Win32.RegistryKey]) -MethodName "OpenBaseKey"

    }

    process
    {
        try
        {
            # Invoke the method overload based on the parameters bound in the dynamic param

            $result = [Microsoft.Win32.RegistryKey]::OpenBaseKey($PSBoundParameters.hkey, $PSBoundParameters.View)
            <#return [pscustomObject]@{
                    ParamSets = $PSCmdlet
                    BoundParam = $PSBoundParameters

                    }#>
            return $result
        }
        catch
        {
            throw
        }
    }
}
function Get-RegistrySubKey
{
    [CmdletBinding()]
    param()

    DynamicParam
    {
        # Step 1: Call the helper function to get dynamic parameters for the OpenSubKey method
        $dynamicParams = Get-DynamicParametersFromMethod -ClassType ([Microsoft.Win32.RegistryKey]) -MethodName "OpenSubKey"

        # Step 2: Extract parameter set names from the dynamic parameters
        $parameterSetNames = $dynamicParams.Values | ForEach-Object {
            $_.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } | ForEach-Object { $_.ParameterSetName }
        } | Select-Object -Unique

        # Step 3: Add additional dynamic parameters using the Add-DynamicParameter function

        # Add 'BaseKey' parameter (mandatory)
        $dynamicParams = Add-DynamicParameter -ParamDictionary $dynamicParams `
            -ParameterSetNames $parameterSetNames `
            -ParameterName 'BaseKey' `
            -ParameterType ([Microsoft.Win32.RegistryKey]) `
            -IsMandatory $true
        Write-Host "Final dynamic parameters: $($dynamicParams.Keys | Out-String)"

        return $dynamicParams
    }

    process
    {
        # Print out the parameters being passed
        $PSBoundParameters | Format-List

        # Continue with the logic
        try
        {
            switch ($PSCmdlet.ParameterSetName)
            {
                'Microsoft.Win32.RegistryKey OpenSubKey(System.String, Boolean)'
                {
                    return $PSBoundParameters.BaseKey.OpenSubKey($PSBoundParameters.Name, $PSBoundParameters.writable)
                }
                'Microsoft.Win32.RegistryKey OpenSubKey(System.String, Microsoft.Win32.RegistryKeyPermissionCheck)'
                {
                    return $PSBoundParameters.BaseKey.OpenSubKey($PSBoundParameters.Name, $PSBoundParameters.permissionCheck)
                }
                'Microsoft.Win32.RegistryKey OpenSubKey(System.String, System.Security.AccessControl.RegistryRights)'
                {
                    return $PSBoundParameters.BaseKey.OpenSubKey($PSBoundParameters.Name, $PSBoundParameters.rights)
                }
                'Microsoft.Win32.RegistryKey OpenSubKey(System.String, Microsoft.Win32.RegistryKeyPermissionCheck, System.Security.AccessControl.RegistryRights)'
                {
                    return $PSBoundParameters.BaseKey.OpenSubKey($PSBoundParameters.Name, $PSBoundParameters.permissionCheck, $PSBoundParameters.rights)
                }
                'Microsoft.Win32.RegistryKey OpenSubKey(System.String)'
                {
                    return $PSBoundParameters.BaseKey.OpenSubKey($PSBoundParameters.Name)
                }
                default
                {
                    throw "Unknown parameter set: $($PSCmdlet.ParameterSetName)"
                }
            }
        }
        catch
        {
            throw
        }
    }
}
function Get-RegistrySubKey
{
    [CmdletBinding()]
    param(

    )

    DynamicParam
    {
        # Step 1: Call the helper function to get dynamic parameters for the OpenSubKey method
        $dynamicParams = Get-DynamicParametersFromMethod -ClassType ([Microsoft.Win32.RegistryKey]) -MethodName "OpenSubKey"

        # Step 2: Extract parameter set names from the dynamic parameters
        $parameterSetNames = $dynamicParams.Values | ForEach-Object {
            $_.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } | ForEach-Object { $_.ParameterSetName }
        } | Select-Object -Unique

        # Step 3: Add additional dynamic parameters using the Add-DynamicParameter function Add 'BaseKey' parameter (optional)
        $dynamicParams = Add-DynamicParameter -ParamDictionary $dynamicParams `
            -ParameterSetNames $parameterSetNames `
            -ParameterName 'BaseKey' `
            -ParameterType ([Microsoft.Win32.RegistryKey]) `
            -IsMandatory $false

        return $dynamicParams



    }

    process
    {
        # Handle the case where BaseKey is not provided (optional parameter)
        if (-not $PSBoundParameters.ContainsKey('BaseKey'))
        {
            throw "BaseKey parameter is required to access the registry."
        }

        # Try executing the OpenSubKey method and handle specific errors
        try
        {
            <#
            switch ($PSCmdlet.ParameterSetName) {
                'Microsoft.Win32.RegistryKey OpenSubKey(System.String, Boolean)' {
                    return $PSBoundParameters.BaseKey.OpenSubKey($PSBoundParameters.Name, $PSBoundParameters.writable)
                }
                'Microsoft.Win32.RegistryKey OpenSubKey(System.String, Microsoft.Win32.RegistryKeyPermissionCheck)' {
                    return $PSBoundParameters.BaseKey.OpenSubKey($PSBoundParameters.Name, $PSBoundParameters.permissionCheck)
                }
                'Microsoft.Win32.RegistryKey OpenSubKey(System.String, System.Security.AccessControl.RegistryRights)' {
                    return $PSBoundParameters.BaseKey.OpenSubKey($PSBoundParameters.Name, $PSBoundParameters.rights)
                }
                'Microsoft.Win32.RegistryKey OpenSubKey(System.String, Microsoft.Win32.RegistryKeyPermissionCheck, System.Security.AccessControl.RegistryRights)' {
                    return $PSBoundParameters.BaseKey.OpenSubKey($PSBoundParameters.Name, $PSBoundParameters.permissionCheck, $PSBoundParameters.rights)
                }
                'Microsoft.Win32.RegistryKey OpenSubKey(System.String)' {
                    return $PSBoundParameters.BaseKey.OpenSubKey($PSBoundParameters.Name)
                }
                default {
                    throw "Unknown parameter set: $($PSCmdlet.ParameterSetName)"
                }
            }
            #>
            # Use the bound parameters and ParameterSetName to invoke the method dynamically
            return Invoke-MethodOverloadFromBoundParam `
                -ParameterSetName $PSCmdlet.ParameterSetName `
                -Parameters $PSBoundParameters `
                -TargetInstance $PSBoundParameters.BaseKey
        }
        catch [System.Security.SecurityException]
        {
            $errorMessage = "SecurityException: Requested registry access is not allowed. Please check your permissions."
            throw [System.Security.SecurityException] $errorMessage
        }
        catch
        {
            Write-Error "An error occurred while accessing the registry: $_"
        }
    }
}
function Get-RegistrySubKey
{
    [CmdletBinding(DefaultParameterSetName = 'DefaultSet')]
    param (
        # Include 'BaseKey' in multiple sets and accept it from the pipeline
        [Parameter(Mandatory = $true, ParameterSetName = 'BooleanSet', ValueFromPipeline = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'PermissionCheckSet', ValueFromPipeline = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'RightsSet', ValueFromPipeline = $true)]
        [Microsoft.Win32.RegistryKey]$BaseKey,

        # 'Name' parameter belongs to all sets
        [Parameter(Mandatory = $true, ParameterSetName = 'BooleanSet')]
        [Parameter(Mandatory = $true, ParameterSetName = 'PermissionCheckSet')]
        [Parameter(Mandatory = $true, ParameterSetName = 'RightsSet')]
        [string]$Name,

        # 'writable' is only in the 'BooleanSet'
        [Parameter(Mandatory = $true, ParameterSetName = 'BooleanSet')]
        [ValidateSet([bool]$true, [bool]$false)]  # Choices for bool parameters
        [bool]$writable,

        # 'permissionCheck' is only in the 'PermissionCheckSet'
        [Parameter(Mandatory = $true, ParameterSetName = 'PermissionCheckSet')]
        [ValidateSet([Microsoft.Win32.RegistryKeyPermissionCheck]::Default,
            [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadSubTree,
            [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree)]
        [Microsoft.Win32.RegistryKeyPermissionCheck]$permissionCheck,

        # 'rights' is only in the 'RightsSet'
        [Parameter(Mandatory = $true, ParameterSetName = 'RightsSet')]
        [ValidateSet([System.Security.AccessControl.RegistryRights]::ReadKey,
            [System.Security.AccessControl.RegistryRights]::WriteKey,
            [System.Security.AccessControl.RegistryRights]::FullControl)]
        [System.Security.AccessControl.RegistryRights]$rights
    )

    process
    {
        try
        {
            switch ($PSCmdlet.ParameterSetName)
            {
                'BooleanSet'
                {
                    return $BaseKey.OpenSubKey($Name, $writable)
                }
                'PermissionCheckSet'
                {
                    return $BaseKey.OpenSubKey($Name, $permissionCheck)
                }
                'RightsSet'
                {
                    return $BaseKey.OpenSubKey($Name, $rights)
                }
                default
                {
                    throw "Unknown parameter set: $($PSCmdlet.ParameterSetName)"
                }
            }
        }
        catch [System.Security.SecurityException]
        {
            $errorMessage = "SecurityException: Requested registry access is not allowed. Please check your permissions."
            throw [System.Security.SecurityException] $errorMessage
        }
        catch
        {
            Write-Error "Error: $_"
        }
    }
}
function Get-RegistrySubKeyNames
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.Win32.RegistryKey]$SubKey
    )

    process
    {
        try
        {
            # Get the subkey names
            $result = $SubKey.GetSubKeyNames()
            return $result
        }
        catch
        {
            throw
        }
    }
}
function Get-RegistryValueNames
{
    [CmdletBinding()]
    param (
        [Microsoft.Win32.RegistryKey]$SubKey
    )

    process
    {
        try
        {
            # Get the subkey names
            $result = $SubKey.GetValueNames()
            return $result
        }
        catch
        {
            throw
        }
    }
}
function Get-RegistryView
{
    [CmdletBinding()]
    param ()

    DynamicParam
    {
        # Create a dynamic parameter dictionary
        $paramDictionary = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary

        # Define the dynamic parameter for RegistryView enum
        $attribute = New-Object System.Management.Automation.ParameterAttribute
        $attribute.Mandatory = $true

        # Add the RegistryView enum values as ValidateSet
        $validateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute([Enum]::GetNames([Microsoft.Win32.RegistryView]))

        # Create the dynamic parameter for RegistryView
        $paramRegistryView = New-Object System.Management.Automation.RuntimeDefinedParameter(
            'RegistryView',
            [Microsoft.Win32.RegistryView],
            @($attribute, $validateSetAttribute)
        )

        # Add the parameter to the dictionary
        $paramDictionary.Add('RegistryView', $paramRegistryView)

        return $paramDictionary
    }

    process
    {
        try
        {
            # Return the selected RegistryView value
            return $PSBoundParameters['RegistryView']
        }
        catch
        {
            Write-Warning "Error: $_"
        }
    }
}
function Get-RegistryValue
{
    [CmdletBinding()]
    param()

    DynamicParam
    {
        # Step 1: Call the helper function to get dynamic parameters for the OpenSubKey method
        $dynamicParams = Get-DynamicParametersFromMethod -ClassType ([Microsoft.Win32.RegistryKey]) -MethodName "GetValue"

        # Step 2: Extract parameter set names from the dynamic parameters
        $parameterSetNames = $dynamicParams.Values | ForEach-Object {
            $_.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } | ForEach-Object { $_.ParameterSetName }
        } | Select-Object -Unique

        # Step 3: Add additional dynamic parameters using the Add-DynamicParameter function

        # Add 'BaseKey' parameter (mandatory)
        $dynamicParams = Add-DynamicParameter -ParamDictionary $dynamicParams `
            -ParameterSetNames $parameterSetNames `
            -ParameterName 'BaseKey' `
            -ParameterType ([Microsoft.Win32.RegistryKey]) `
            -IsMandatory $true

        return $dynamicParams
    }

    process
    {
        try
        {
            return $PSBoundParameters.BaseKey.GetValue($PSBoundParameters.name)
        }
        catch
        {
            throw
        }
    }
}






$BaseKey = Get-RegistryBaseKey -hKey LocalMachine -view Default | Get-RegistrySubKey -Name $RegistryPath -writable $False | Get-RegistrySubKeyNames

$RegistryPath = "SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
$SubKey = Get-RegistrySubKey -BaseKey $BaseKey -writable $false -Name $RegistryPath




$subkeyNames = Get-RegistrySubKeyNames -SubKey $SubKey


$Subkey2 = Get-RegistrySubKey -name "$RegistryPath\$($subkeyNames[4])" -writable $false -BaseKey $baseKey

Get-RegistryValueNames -SubKey $SubKey2
