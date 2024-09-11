<#
.SYNOPSIS
Exports a specified registry key to a file using the `reg.exe` utility.

.DESCRIPTION
The `Invoke-RegCommand` function leverages the `reg.exe` command-line utility to export a specified registry key to a file. It accepts the registry path and export path as parameters, with default values provided by the environment variables `$ENV:Registry_Path` and `$ENV:Export_Path`. The function wraps this behavior in a PowerShell `Invoke-Command` call to execute the `reg.exe` command in the current session.

.PARAMETER RegistryPath
Specifies the path to the registry key that will be exported. If not provided, the function defaults to the value of the `$ENV:Registry_Path` environment variable.

.PARAMETER ExportPath
Specifies the file path where the registry export will be saved. If not provided, the function defaults to the value of the `$ENV:Export_Path` environment variable.

.EXAMPLE
Invoke-RegCommand -RegistryPath "HKCU\Software\MyKey" -ExportPath "C:\Export\mykey.reg"

This example exports the registry key `HKCU\Software\MyKey` to the file `C:\Export\mykey.reg`.

.EXAMPLE
$ENV:Registry_Path = "HKLM\Software\MyApp"
$ENV:Export_Path = "D:\Backup\myapp.reg"
Invoke-RegCommand

This example exports the registry key from the environment variable `Registry_Path` to the file path specified in `Export_Path`.

.NOTES
- The function requires the `reg.exe` utility, which is available on Windows operating systems by default.
- The registry and export paths can be passed as parameters or set via environment variables.
- Ensure the correct permissions are available for accessing the registry and writing to the specified output path.

#>

Function Invoke-RegCommand
{
    param(
        [string]$RegistryPath = $ENV:Registry_Path,
        [string]$ExportPath = $ENV:Export_Path
    )

    $Parameters = @{
        Operation  = 'EXPORT'
        Path       = $RegistryPath
        OutputFile = $ExportPath
    }

    if (-not [string]::IsNullOrEmpty($Parameters.Path) -and -not [string]::IsNullOrEmpty($Parameters.OutputFile))
    {
        $result = Invoke-Command -ScriptBlock {
            param($Parameters)
            &reg $Parameters.Operation $Parameters.Path $Parameters.OutputFile
        } -ArgumentList $Parameters

        return $result
    }
    else
    {
        throw "Path or OutputFile is null or empty."
    }
}
