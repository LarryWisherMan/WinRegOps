# File: TestHelpers.ps1
function Log-TestDetails
{
    param (
        [string]$TestName,
        [psobject]$Details,
        [string]$AdditionalInfo
    )

    Write-Host "==========================================="
    Write-Host "Test Name: $TestName"
    Write-Host "==========================================="

    Write-Host "Details:"
    if ($null -ne $Details)
    {
        Write-Host "-------------------------------------------"
        Write-Host $($Details | Out-String) | Out-String
    }
    else
    {
        Write-Host "No details available."
    }
    Write-Host "-------------------------------------------"

    if ($null -ne $AdditionalInfo)
    {
        Write-Host "Additional Info:"
        Write-Host "-------------------------------------------"
        Write-Host $AdditionalInfo
        Write-Host "-------------------------------------------"
    }

    Write-Host "Last Error (if any):"
    if ($Error.Count -gt 0)
    {
        Write-Host "-------------------------------------------"
        Write-Host ($Error[0] | Out-String)  # Display only the last error
        Write-Host "-------------------------------------------"
    }
    else
    {
        Write-Host "No errors recorded."
    }

    Write-Host "==========================================="
}


Write-Host "Log-TestDetails Imported" -ForegroundColor Yellow
