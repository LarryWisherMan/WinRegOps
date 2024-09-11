function Invoke-RegCommand {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("QUERY", "ADD", "DELETE", "COPY", "SAVE", "LOAD", "UNLOAD", "COMPARE", "EXPORT", "IMPORT", "RESTORE", "BACKUP", "RESTORE", "FLAGS")]
        [string]$Operation,

        [Parameter(Mandatory = $true)]
        [string]$Path,

        [string]$ValueName,

        [string]$ValueData,

        [ValidateSet("REG_SZ", "REG_DWORD", "REG_BINARY", "REG_MULTI_SZ", "REG_EXPAND_SZ")]
        [string]$ValueType,

        [string]$OutputFile,

        [string]$ComputerName = $null,

        [Switch]$PassThru
    )

    # Build argument list based on operation
    $arguments = "$Operation `"$Path`""

    if ($Operation -eq "EXPORT") {
        if (-not $OutputFile) {
            throw "You must specify an output file when using the EXPORT operation."
        }
        $arguments += " `"$OutputFile`" /y"
    }
    elseif ($ValueName) {
        $arguments += " /v `"$ValueName`""
    }

    if ($ValueData) {
        $arguments += " /d `"$ValueData`""
    }

    if ($ValueType) {
        $arguments += " /t $ValueType"
    }

    # Local execution using Start-Process
    if (-not $ComputerName) {
        try {
            Write-Verbose "Executing locally"
            $processInfo = Start-Process -FilePath "reg.exe" -ArgumentList $arguments -NoNewWindow -PassThru -Wait
            if ($processInfo.ExitCode -eq 0) {
                Write-Host "Command executed successfully."
            }
            else {
                Write-Error "Failed to execute reg command. Exit code: $($processInfo.ExitCode)"
            }
        }
        catch {
            Write-Error "Failed to execute reg command locally: $_"
        }
    }
    else {
        # Remote execution using Invoke-Command
        try {
            Write-Verbose "Executing remotely on $ComputerName"
            $result = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                param($operation, $path, $valueName, $valueData, $valueType, $outputFile)
                $arguments = "$operation `"$path`""
                if ($operation -eq "EXPORT") {
                    $arguments += " `"$outputFile`" /y"
                }
                elseif ($valueName) {
                    $arguments += " /v `"$valueName`""
                }
                if ($valueData) {
                    $arguments += " /d `"$valueData`""
                }
                if ($valueType) {
                    $arguments += " /t $valueType"
                }

                Start-Process -FilePath "reg.exe" -ArgumentList $arguments -NoNewWindow -Wait -PassThru
            } -ArgumentList $Operation, $Path, $ValueName, $ValueData, $ValueType, $OutputFile
        }
        catch {
            Write-Error "Failed to execute reg command on $ComputerName`: $_"
        }
    }
}
