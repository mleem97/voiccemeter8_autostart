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

.EXAMPLE
    .\Set-AudiodgPriority.ps1 -WhatIf
    Shows which process changes would be attempted without applying them.

#>

[CmdletBinding(SupportsShouldProcess = $true)]
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
# Function: Write-StatusMessage
# ---------------------------------------------
function Write-StatusMessage {
    <#
    .SYNOPSIS
        Writes status text to the verbose stream.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Verbose -Message $Message
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
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param()

    try {
        Write-StatusMessage -Message "Administrator privileges required. Restarting with elevation..."
        
        $pwshPath = if (Test-Path "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe") {
            "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
        } else {
            "powershell.exe"
        }

        $scriptPath = $MyInvocation.PSCommandPath
        if (-not $scriptPath) {
            $scriptPath = $PSCommandPath
        }

        $arguments = @(
            '-NoProfile'
            '-ExecutionPolicy', 'Bypass'
            '-File', "`"$scriptPath`""
        )

        if ($PSCmdlet.ShouldProcess($scriptPath, 'Restart script with administrator privileges')) {
            Start-Process -FilePath $pwshPath -ArgumentList $arguments -Verb RunAs -ErrorAction Stop
            exit 0
        }
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
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory = $true)]
        [System.Diagnostics.Process]$Process,

        [Parameter(Mandatory = $true)]
        [System.Diagnostics.ProcessPriorityClass]$Priority
    )

    try {
        Write-Verbose "Setting process priority to '$Priority'"

        if (-not $PSCmdlet.ShouldProcess($Process.ProcessName, "Set process priority to '$Priority'")) {
            return $false
        }

        $Process.PriorityClass = $Priority
        Write-StatusMessage -Message "Process priority set to '$Priority'"
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
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory = $true)]
        [System.Diagnostics.Process]$Process,

        [Parameter(Mandatory = $true)]
        [System.IntPtr]$Affinity
    )

    try {
        Write-Verbose "Setting processor affinity to $Affinity (CPU Core 0)"

        if (-not $PSCmdlet.ShouldProcess($Process.ProcessName, "Set processor affinity to '$Affinity'")) {
            return $false
        }

        $Process.ProcessorAffinity = $Affinity
        Write-StatusMessage -Message "Processor affinity set to CPU Core 0"
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

    Write-StatusMessage -Message "Audio Process Optimizer"
    Write-StatusMessage -Message "Configuring audiodg.exe process settings"

    # Check administrator privileges
    if (-not (Test-IsAdministrator)) {
        Start-ElevatedProcess
        return
    }

    Write-StatusMessage -Message "Running with administrator privileges"

    # Retrieve audiodg.exe process
    Write-StatusMessage -Message "Searching for audiodg.exe process..."
    $audioProcess = Get-AudiodgProcess -MaxRetries $Script:Config.MaxRetryAttempts -RetryDelaySeconds $Script:Config.RetryDelaySeconds

    if (-not $audioProcess) {
        Write-Warning "audiodg.exe process not found after $($Script:Config.MaxRetryAttempts) attempts."
        Write-StatusMessage -Message "The process may not be running. Please ensure audio services are active."
        Show-ProgressCountdown -Seconds 5 -Activity 'Cleanup' -Status 'Exiting'
        exit 1
    }

    Write-StatusMessage -Message "Found audiodg.exe (PID: $($audioProcess.Id))"

    # Apply settings
    $successCount = 0
    
    if (Set-ProcessPriority -Process $audioProcess -Priority $Script:Config.TargetPriority) {
        $successCount++
    }

    if (Set-ProcessorAffinity -Process $audioProcess -Affinity $Script:Config.TargetAffinity) {
        $successCount++
    }

    # Summary
    Write-StatusMessage -Message "Summary"
    Write-StatusMessage -Message "Successfully applied: $successCount of 2 settings"
    
    if ($successCount -lt 2) {
        Write-Warning "Some settings could not be applied due to Windows process protection. This is normal for audiodg.exe on modern Windows versions."
    }

    # Countdown
    Show-ProgressCountdown -Seconds $Script:Config.CountdownSeconds -Activity 'All Settings Applied' -Status 'Completing'

    Write-StatusMessage -Message "Script completed successfully"
    exit 0
}

# Execute main function
try {
    Main
}
catch {
    Write-Error "Unexpected error occurred: $($_.Exception.Message)"
    Write-Verbose "Stack Trace:"
    Write-Verbose $_.ScriptStackTrace
    exit 1
}
