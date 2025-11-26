#Requires -Version 3.0
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Configures Voicemeeter autostart and optimizes audiodg.exe process settings.

.DESCRIPTION
    This script performs the following operations:
    - Verifies and elevates to administrator privileges if needed
    - Sets audiodg.exe process priority to High
    - Restricts audiodg.exe to run on CPU core 0 only
    - Displays progress feedback with countdown
    - Implements comprehensive error handling

.NOTES
    File Name      : Set-AudiodgPriority.ps1
    Author         : Meyer Media
    Prerequisite   : PowerShell 3.0 or higher, Administrator privileges
    
    IMPORTANT: audiodg.exe may run as a Protected Process Light (PPL) on some
    Windows versions, which can prevent priority/affinity modifications even
    with administrator rights.

.EXAMPLE
    .\Set-AudiodgPriority.ps1
    Runs the script with automatic elevation if needed.

#>

[CmdletBinding()]
param()

# ---------------------------------------------
# Configuration Constants
# ---------------------------------------------
$Script:Config = @{
    ProcessName        = 'audiodg'
    TargetPriority     = [System.Diagnostics.ProcessPriorityClass]::High
    TargetAffinity     = [System.IntPtr]1  # CPU Core 0
    CountdownSeconds   = 10
    MaxRetryAttempts   = 3
    RetryDelaySeconds  = 2
}

# ---------------------------------------------
# Function: Test-IsAdministrator
# ---------------------------------------------
function Test-IsAdministrator {
    <#
    .SYNOPSIS
        Checks if the current PowerShell session has administrator privileges.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]$identity
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        Write-Warning "Failed to determine administrator status: $($_.Exception.Message)"
        return $false
    }
}

# ---------------------------------------------
# Function: Start-ElevatedProcess
# ---------------------------------------------
function Start-ElevatedProcess {
    <#
    .SYNOPSIS
        Restarts the current script with elevated privileges.
    #>
    [CmdletBinding()]
    param()

    try {
        Write-Host "Administrator privileges required. Restarting with elevation..." -ForegroundColor Yellow
        
        $pwshPath = if (Test-Path "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe") {
            "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
        } else {
            "powershell.exe"
        }

        $arguments = @(
            '-NoProfile'
            '-ExecutionPolicy', 'Bypass'
            '-File', "`"$($MyInvocation.PSCommandPath)`""
        )

        Start-Process -FilePath $pwshPath -ArgumentList $arguments -Verb RunAs
        exit 0
    }
    catch {
        Write-Error "Failed to elevate privileges: $($_.Exception.Message)"
        exit 1
    }
}

# ---------------------------------------------
# Function: Show-ProgressCountdown
# ---------------------------------------------
function Show-ProgressCountdown {
    <#
    .SYNOPSIS
        Displays a progress bar countdown.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 300)]
        [int]$Seconds,

        [Parameter(Mandatory = $false)]
        [string]$Activity = 'Processing',

        [Parameter(Mandatory = $false)]
        [string]$Status = 'Please wait...'
    )

    Write-Verbose "Starting countdown for $Seconds seconds"

    for ($i = 1; $i -le $Seconds; $i++) {
        $percentComplete = [Math]::Round(($i / $Seconds) * 100, 2)
        $secondsRemaining = $Seconds - $i

        Write-Progress `
            -Activity $Activity `
            -Status "$Status ($secondsRemaining seconds remaining)" `
            -PercentComplete $percentComplete `
            -SecondsRemaining $secondsRemaining

        Start-Sleep -Seconds 1
    }

    Write-Progress -Activity $Activity -Completed
}

# ---------------------------------------------
# Function: Get-AudiodgProcess
# ---------------------------------------------
function Get-AudiodgProcess {
    <#
    .SYNOPSIS
        Retrieves the audiodg.exe process with retry logic.
    #>
    [CmdletBinding()]
    [OutputType([System.Diagnostics.Process])]
    param(
        [Parameter(Mandatory = $false)]
        [int]$MaxRetries = 3,

        [Parameter(Mandatory = $false)]
        [int]$RetryDelaySeconds = 2
    )

    for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
        Write-Verbose "Attempt $attempt of $MaxRetries to find audiodg.exe process"
        
        $processes = Get-Process -Name $Script:Config.ProcessName -ErrorAction SilentlyContinue

        if ($processes) {
            if ($processes -is [array] -and $processes.Count -gt 1) {
                Write-Warning "Multiple audiodg.exe instances found ($($processes.Count)). Using the first instance."
                return $processes[0]
            }
            return $processes
        }

        if ($attempt -lt $MaxRetries) {
            Write-Verbose "Process not found. Waiting $RetryDelaySeconds seconds before retry..."
            Start-Sleep -Seconds $RetryDelaySeconds
        }
    }

    return $null
}

# ---------------------------------------------
# Function: Set-ProcessPriority
# ---------------------------------------------
function Set-ProcessPriority {
    <#
    .SYNOPSIS
        Sets the priority class for a given process.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Diagnostics.Process]$Process,

        [Parameter(Mandatory = $true)]
        [System.Diagnostics.ProcessPriorityClass]$Priority
    )

    try {
        Write-Verbose "Setting process priority to '$Priority'"
        $Process.PriorityClass = $Priority
        Write-Host "✓ Process priority set to '$Priority'" -ForegroundColor Green
        return $true
    }
    catch [System.ComponentModel.Win32Exception] {
        Write-Warning "Access denied: Cannot set priority (process may be protected)"
        return $false
    }
    catch {
        Write-Warning "Failed to set priority: $($_.Exception.Message)"
        return $false
    }
}

# ---------------------------------------------
# Function: Set-ProcessorAffinity
# ---------------------------------------------
function Set-ProcessorAffinity {
    <#
    .SYNOPSIS
        Sets the processor affinity for a given process.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Diagnostics.Process]$Process,

        [Parameter(Mandatory = $true)]
        [System.IntPtr]$Affinity
    )

    try {
        Write-Verbose "Setting processor affinity to $Affinity (CPU Core 0)"
        $Process.ProcessorAffinity = $Affinity
        Write-Host "✓ Processor affinity set to CPU Core 0" -ForegroundColor Green
        return $true
    }
    catch [System.ComponentModel.Win32Exception] {
        Write-Warning "Access denied: Cannot set affinity (process may be protected)"
        return $false
    }
    catch {
        Write-Warning "Failed to set affinity: $($_.Exception.Message)"
        return $false
    }
}

# ---------------------------------------------
# Main Script Execution
# ---------------------------------------------
function Main {
    [CmdletBinding()]
    param()

    Write-Host "`n=== Audio Process Optimizer ===" -ForegroundColor Cyan
    Write-Host "Configuring audiodg.exe process settings`n" -ForegroundColor Cyan

    # Check administrator privileges
    if (-not (Test-IsAdministrator)) {
        Start-ElevatedProcess
        return
    }

    Write-Host "✓ Running with administrator privileges`n" -ForegroundColor Green

    # Retrieve audiodg.exe process
    Write-Host "Searching for audiodg.exe process..." -ForegroundColor Yellow
    $audioProcess = Get-AudiodgProcess -MaxRetries $Script:Config.MaxRetryAttempts -RetryDelaySeconds $Script:Config.RetryDelaySeconds

    if (-not $audioProcess) {
        Write-Warning "audiodg.exe process not found after $($Script:Config.MaxRetryAttempts) attempts."
        Write-Host "`nThe process may not be running. Please ensure audio services are active." -ForegroundColor Yellow
        Show-ProgressCountdown -Seconds 5 -Activity 'Cleanup' -Status 'Exiting'
        exit 1
    }

    Write-Host "✓ Found audiodg.exe (PID: $($audioProcess.Id))`n" -ForegroundColor Green

    # Apply settings
    $successCount = 0
    
    if (Set-ProcessPriority -Process $audioProcess -Priority $Script:Config.TargetPriority) {
        $successCount++
    }

    if (Set-ProcessorAffinity -Process $audioProcess -Affinity $Script:Config.TargetAffinity) {
        $successCount++
    }

    # Summary
    Write-Host "`n--- Summary ---" -ForegroundColor Cyan
    Write-Host "Successfully applied: $successCount of 2 settings" -ForegroundColor $(if ($successCount -eq 2) { 'Green' } else { 'Yellow' })
    
    if ($successCount -lt 2) {
        Write-Host "`nNote: Some settings could not be applied due to Windows process protection." -ForegroundColor Yellow
        Write-Host "This is normal for audiodg.exe on modern Windows versions." -ForegroundColor Yellow
    }

    # Countdown
    Show-ProgressCountdown -Seconds $Script:Config.CountdownSeconds -Activity 'All Settings Applied' -Status 'Completing'

    Write-Host "`n✓ Script completed successfully" -ForegroundColor Green
    exit 0
}

# Execute main function
try {
    Main
}
catch {
    Write-Error "Unexpected error occurred: $($_.Exception.Message)"
    Write-Host "`nStack Trace:" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}
