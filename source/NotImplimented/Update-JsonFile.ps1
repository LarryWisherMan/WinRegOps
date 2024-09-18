function Update-JsonFile {
    param (
        [Parameter(Mandatory = $true)]
        [string]$OutputFile,

        [Parameter(Mandatory = $true)]
        [array]$RegistryData  # Generic data for registry keys
    )

    if (Test-Path $OutputFile) {
        $existingData = Get-Content -Path $OutputFile | ConvertFrom-Json
        $existingData += $RegistryData
        $existingData | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputFile
    } else {
        $RegistryData | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputFile
    }
}
