#Requires -Version 3.0
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Configures Voicemeeter autostart and optimizes audiodg.exe process settings.

.DESCRIPTION
    This script performs the following operations:
    - Verifies and elevates to administrator privileges if needed
    - Starts Voicemeeter if not running
    - Sets audiodg.exe and Voicemeeter process priority to High
    - Restricts both processes to run on CPU core 0 only
    - Displays GUI notifications for status updates
    - Implements comprehensive error handling with visual feedback

.NOTES
    File Name      : Start-VoicemeeterOptimized.ps1
    Author         : Meyer Media
    Prerequisite   : PowerShell 3.0 or higher, Administrator privileges
    
    IMPORTANT: audiodg.exe may run as a Protected Process Light (PPL) on some
    Windows versions, which can prevent priority/affinity modifications even
    with administrator rights.

.EXAMPLE
    .\Start-VoicemeeterOptimized.ps1
    Runs the script with automatic elevation if needed.

#>

[CmdletBinding()]
param()

# Load Windows Forms for GUI notifications
Add-Type -AssemblyName System.Windows.Forms

# ---------------------------------------------
# Configuration Constants
# ---------------------------------------------
$Script:Config = @{
    AudiodgProcessName      = 'audiodg'
    VoicemeeterProcessName  = 'voicemeeter8x64'
    VoicemeeterExecutable   = 'C:\Program Files (x86)\VB\Voicemeeter\voicemeeter8x64.exe'
    TargetPriority          = [System.Diagnostics.ProcessPriorityClass]::High
    TargetAffinity          = [System.IntPtr]1  # CPU Core 0
    MaxRetryAttempts        = 3
    RetryDelaySeconds       = 2
    VoicemeeterStartupDelay = 3  # Seconds to wait after starting Voicemeeter
}

# Track success/failure for final summary
$Script:Results = @{
    AudiodgFound        = $false
    AudiodgPriority     = $false
    AudiodgAffinity     = $false
    VoicemeeterFound    = $false
    VoicemeeterStarted  = $false
    VoicemeeterPriority = $false
    VoicemeeterAffinity = $false
    Errors              = @()
}

# ---------------------------------------------
# Function: Show-Notification
# ---------------------------------------------
function Show-Notification {
    <#
    .SYNOPSIS
        Displays a GUI message box notification.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$Title = 'Audio Optimizer',

        [Parameter(Mandatory = $false)]
        [ValidateSet('Information', 'Warning', 'Error', 'Question')]
        [string]$Type = 'Information',

        [Parameter(Mandatory = $false)]
        [switch]$NoConsole
    )

    $icon = switch ($Type) {
        'Information' { [System.Windows.Forms.MessageBoxIcon]::Information }
        'Warning'     { [System.Windows.Forms.MessageBoxIcon]::Warning }
        'Error'       { [System.Windows.Forms.MessageBoxIcon]::Error }
        'Question'    { [System.Windows.Forms.MessageBoxIcon]::Question }
    }

    if (-not $NoConsole) {
        $color = switch ($Type) {
            'Information' { 'Cyan' }
            'Warning'     { 'Yellow' }
            'Error'       { 'Red' }
            'Question'    { 'White' }
        }
        Write-Host "[$Type] $Message" -ForegroundColor $color
    }

    [System.Windows.Forms.MessageBox]::Show(
        $Message,
        $Title,
        [System.Windows.Forms.MessageBoxButtons]::OK,
        $icon
    ) | Out-Null
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
        Show-Notification -Message "Failed to elevate privileges: $($_.Exception.Message)" -Type Error
        exit 1
    }
}

# ---------------------------------------------
# Function: Get-ProcessWithRetry
# ---------------------------------------------
function Get-ProcessWithRetry {
    <#
    .SYNOPSIS
        Retrieves a process with retry logic.
    #>
    [CmdletBinding()]
    [OutputType([System.Diagnostics.Process])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProcessName,

        [Parameter(Mandatory = $false)]
        [int]$MaxRetries = 3,

        [Parameter(Mandatory = $false)]
        [int]$RetryDelaySeconds = 2
    )

    for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
        Write-Verbose "Attempt $attempt of $MaxRetries to find $ProcessName process"
        
        $processes = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue

        if ($processes) {
            if ($processes -is [array] -and $processes.Count -gt 1) {
                Write-Verbose "Multiple $ProcessName instances found ($($processes.Count)). Using the first instance."
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
        [System.Diagnostics.ProcessPriorityClass]$Priority,

        [Parameter(Mandatory = $true)]
        [string]$ProcessDisplayName
    )

    try {
        Write-Verbose "Setting $ProcessDisplayName priority to '$Priority'"
        $Process.PriorityClass = $Priority
        Write-Host "✓ $ProcessDisplayName priority set to '$Priority'" -ForegroundColor Green
        return $true
    }
    catch [System.ComponentModel.Win32Exception] {
        $errorMsg = "Access denied: Cannot set priority for $ProcessDisplayName (process may be protected)"
        Write-Warning $errorMsg
        $Script:Results.Errors += $errorMsg
        return $false
    }
    catch {
        $errorMsg = "Failed to set priority for $ProcessDisplayName : $($_.Exception.Message)"
        Write-Warning $errorMsg
        $Script:Results.Errors += $errorMsg
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
        [System.IntPtr]$Affinity,

        [Parameter(Mandatory = $true)]
        [string]$ProcessDisplayName
    )

    try {
        Write-Verbose "Setting $ProcessDisplayName processor affinity to CPU Core 0"
        $Process.ProcessorAffinity = $Affinity
        Write-Host "✓ $ProcessDisplayName processor affinity set to CPU Core 0" -ForegroundColor Green
        return $true
    }
    catch [System.ComponentModel.Win32Exception] {
        $errorMsg = "Access denied: Cannot set affinity for $ProcessDisplayName (process may be protected)"
        Write-Warning $errorMsg
        $Script:Results.Errors += $errorMsg
        return $false
    }
    catch {
        $errorMsg = "Failed to set affinity for $ProcessDisplayName : $($_.Exception.Message)"
        Write-Warning $errorMsg
        $Script:Results.Errors += $errorMsg
        return $false
    }
}

# ---------------------------------------------
# Function: Optimize-AudiodgProcess
# ---------------------------------------------
function Optimize-AudiodgProcess {
    <#
    .SYNOPSIS
        Finds and optimizes the audiodg.exe process.
    #>
    [CmdletBinding()]
    param()

    Write-Host "`n--- Configuring audiodg.exe ---" -ForegroundColor Cyan
    
    try {
        $audioProcess = Get-ProcessWithRetry -ProcessName $Script:Config.AudiodgProcessName -MaxRetries $Script:Config.MaxRetryAttempts -RetryDelaySeconds $Script:Config.RetryDelaySeconds

        if (-not $audioProcess) {
            Write-Host "⚠ audiodg.exe process not found" -ForegroundColor Yellow
            Show-Notification -Message "audiodg.exe was not found or is not currently running." -Type Information -NoConsole
            return
        }

        $Script:Results.AudiodgFound = $true
        Write-Host "✓ Found audiodg.exe (PID: $($audioProcess.Id))" -ForegroundColor Green

        # Set priority
        $Script:Results.AudiodgPriority = Set-ProcessPriority -Process $audioProcess -Priority $Script:Config.TargetPriority -ProcessDisplayName 'audiodg.exe'

        # Set affinity
        $Script:Results.AudiodgAffinity = Set-ProcessorAffinity -Process $audioProcess -Affinity $Script:Config.TargetAffinity -ProcessDisplayName 'audiodg.exe'

        if ($Script:Results.AudiodgPriority -and $Script:Results.AudiodgAffinity) {
            Show-Notification -Message "audiodg.exe has been successfully optimized." -Type Information -NoConsole
        }
    }
    catch {
        $errorMsg = "Error while processing audiodg.exe: $($_.Exception.Message)"
        Write-Warning $errorMsg
        $Script:Results.Errors += $errorMsg
        Show-Notification -Message "Failed to configure audiodg.exe: $($_.Exception.Message)" -Type Error -NoConsole
    }
}

# ---------------------------------------------
# Function: Start-VoicemeeterApplication
# ---------------------------------------------
function Start-VoicemeeterApplication {
    <#
    .SYNOPSIS
        Starts the Voicemeeter application if not running.
    #>
    [CmdletBinding()]
    param()

    Write-Host "`n--- Configuring Voicemeeter ---" -ForegroundColor Cyan

    # Check if Voicemeeter is already running
    $voicemeeterProcess = Get-ProcessWithRetry -ProcessName $Script:Config.VoicemeeterProcessName -MaxRetries 1 -RetryDelaySeconds 1

    if ($voicemeeterProcess) {
        $Script:Results.VoicemeeterFound = $true
        Write-Host "✓ Voicemeeter is already running (PID: $($voicemeeterProcess.Id))" -ForegroundColor Green
        return $voicemeeterProcess
    }

    # Check if executable exists
    if (-not (Test-Path $Script:Config.VoicemeeterExecutable)) {
        $errorMsg = "Voicemeeter executable not found at: $($Script:Config.VoicemeeterExecutable)"
        Write-Warning $errorMsg
        $Script:Results.Errors += $errorMsg
        Show-Notification -Message "Voicemeeter executable not found. Please verify the installation path." -Type Warning -NoConsole
        return $null
    }

    # Start Voicemeeter
    try {
        Write-Host "Starting Voicemeeter..." -ForegroundColor Yellow
        Start-Process -FilePath $Script:Config.VoicemeeterExecutable -ErrorAction Stop
        
        Write-Host "Waiting $($Script:Config.VoicemeeterStartupDelay) seconds for Voicemeeter to initialize..." -ForegroundColor Yellow
        Start-Sleep -Seconds $Script:Config.VoicemeeterStartupDelay

        # Verify it started
        $voicemeeterProcess = Get-ProcessWithRetry -ProcessName $Script:Config.VoicemeeterProcessName -MaxRetries 2 -RetryDelaySeconds 2

        if ($voicemeeterProcess) {
            $Script:Results.VoicemeeterStarted = $true
            Write-Host "✓ Voicemeeter started successfully (PID: $($voicemeeterProcess.Id))" -ForegroundColor Green
            Show-Notification -Message "Voicemeeter has been started successfully." -Type Information -NoConsole
            return $voicemeeterProcess
        }
        else {
            $errorMsg = "Voicemeeter was started but process could not be found"
            Write-Warning $errorMsg
            $Script:Results.Errors += $errorMsg
            return $null
        }
    }
    catch {
        $errorMsg = "Failed to start Voicemeeter: $($_.Exception.Message)"
        Write-Warning $errorMsg
        $Script:Results.Errors += $errorMsg
        Show-Notification -Message "Failed to start Voicemeeter: $($_.Exception.Message)" -Type Error -NoConsole
        return $null
    }
}

# ---------------------------------------------
# Function: Optimize-VoicemeeterProcess
# ---------------------------------------------
function Optimize-VoicemeeterProcess {
    <#
    .SYNOPSIS
        Optimizes the Voicemeeter process (priority and affinity).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [System.Diagnostics.Process]$Process
    )

    if (-not $Process) {
        Write-Host "⚠ Voicemeeter process not available for optimization" -ForegroundColor Yellow
        return
    }

    try {
        # Set priority
        $Script:Results.VoicemeeterPriority = Set-ProcessPriority -Process $Process -Priority $Script:Config.TargetPriority -ProcessDisplayName 'Voicemeeter'

        # Set affinity
        $Script:Results.VoicemeeterAffinity = Set-ProcessorAffinity -Process $Process -Affinity $Script:Config.TargetAffinity -ProcessDisplayName 'Voicemeeter'

        if ($Script:Results.VoicemeeterPriority -and $Script:Results.VoicemeeterAffinity) {
            Show-Notification -Message "Voicemeeter has been successfully optimized." -Type Information -NoConsole
        }
    }
    catch {
        $errorMsg = "Error while optimizing Voicemeeter: $($_.Exception.Message)"
        Write-Warning $errorMsg
        $Script:Results.Errors += $errorMsg
        Show-Notification -Message "Failed to optimize Voicemeeter: $($_.Exception.Message)" -Type Error -NoConsole
    }
}

# ---------------------------------------------
# Function: Show-FinalSummary
# ---------------------------------------------
function Show-FinalSummary {
    <#
    .SYNOPSIS
        Displays a summary of all operations performed.
    #>
    [CmdletBinding()]
    param()

    Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║         Operation Summary              ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan

    # Audiodg summary
    Write-Host "`nAudiodg.exe:" -ForegroundColor Yellow
    Write-Host "  Found:    $(if ($Script:Results.AudiodgFound) { '✓' } else { '✗' })" -ForegroundColor $(if ($Script:Results.AudiodgFound) { 'Green' } else { 'Red' })
    if ($Script:Results.AudiodgFound) {
        Write-Host "  Priority: $(if ($Script:Results.AudiodgPriority) { '✓' } else { '✗' })" -ForegroundColor $(if ($Script:Results.AudiodgPriority) { 'Green' } else { 'Yellow' })
        Write-Host "  Affinity: $(if ($Script:Results.AudiodgAffinity) { '✓' } else { '✗' })" -ForegroundColor $(if ($Script:Results.AudiodgAffinity) { 'Green' } else { 'Yellow' })
    }

    # Voicemeeter summary
    Write-Host "`nVoicemeeter:" -ForegroundColor Yellow
    if ($Script:Results.VoicemeeterStarted) {
        Write-Host "  Started:  ✓" -ForegroundColor Green
    }
    elseif ($Script:Results.VoicemeeterFound) {
        Write-Host "  Running:  ✓" -ForegroundColor Green
    }
    else {
        Write-Host "  Status:   ✗" -ForegroundColor Red
    }

    if ($Script:Results.VoicemeeterFound -or $Script:Results.VoicemeeterStarted) {
        Write-Host "  Priority: $(if ($Script:Results.VoicemeeterPriority) { '✓' } else { '✗' })" -ForegroundColor $(if ($Script:Results.VoicemeeterPriority) { 'Green' } else { 'Yellow' })
        Write-Host "  Affinity: $(if ($Script:Results.VoicemeeterAffinity) { '✓' } else { '✗' })" -ForegroundColor $(if ($Script:Results.VoicemeeterAffinity) { 'Green' } else { 'Yellow' })
    }

    # Errors
    if ($Script:Results.Errors.Count -gt 0) {
        Write-Host "`nWarnings/Errors:" -ForegroundColor Red
        foreach ($error in $Script:Results.Errors) {
            Write-Host "  • $error" -ForegroundColor Yellow
        }
    }

    # Calculate success
    $totalOperations = 0
    $successfulOperations = 0

    if ($Script:Results.AudiodgFound) {
        $totalOperations += 2
        if ($Script:Results.AudiodgPriority) { $successfulOperations++ }
        if ($Script:Results.AudiodgAffinity) { $successfulOperations++ }
    }

    if ($Script:Results.VoicemeeterFound -or $Script:Results.VoicemeeterStarted) {
        $totalOperations += 2
        if ($Script:Results.VoicemeeterPriority) { $successfulOperations++ }
        if ($Script:Results.VoicemeeterAffinity) { $successfulOperations++ }
    }

    # Final message
    $finalMessage = if ($totalOperations -eq 0) {
        "⚠ No processes were found or configured."
    }
    elseif ($successfulOperations -eq $totalOperations) {
        "✓ All operations completed successfully! ($successfulOperations/$totalOperations)"
    }
    else {
        "⚠ Partial success: $successfulOperations of $totalOperations operations completed."
    }

    Write-Host "`n$finalMessage" -ForegroundColor $(if ($successfulOperations -eq $totalOperations -and $totalOperations -gt 0) { 'Green' } elseif ($totalOperations -eq 0) { 'Yellow' } else { 'Yellow' })

    # GUI notification
    $guiMessage = if ($totalOperations -eq 0) {
        "No processes were found to configure.`n`nPlease ensure audio services and Voicemeeter are available."
    }
    elseif ($successfulOperations -eq $totalOperations) {
        "All audio optimizations applied successfully! :)`n`nAudiodg and Voicemeeter are configured for optimal performance."
    }
    else {
        "Audio optimization partially completed.`n`n$successfulOperations of $totalOperations operations succeeded.`n`nSome settings may be blocked by Windows process protection."
    }

    Show-Notification -Message $guiMessage -Type $(if ($successfulOperations -eq $totalOperations -and $totalOperations -gt 0) { 'Information' } else { 'Warning' })
}

# ---------------------------------------------
# Main Script Execution
# ---------------------------------------------
function Main {
    [CmdletBinding()]
    param()

    Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║   Audio Process Optimizer for          ║" -ForegroundColor Cyan
    Write-Host "║   Voicemeeter & Audiodg                ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════╝`n" -ForegroundColor Cyan

    # Check administrator privileges
    if (-not (Test-IsAdministrator)) {
        Start-ElevatedProcess
        return
    }

    Write-Host "✓ Running with administrator privileges`n" -ForegroundColor Green

    # Process audiodg.exe
    Optimize-AudiodgProcess

    # Start and optimize Voicemeeter
    $voicemeeterProcess = Start-VoicemeeterApplication
    Optimize-VoicemeeterProcess -Process $voicemeeterProcess

    # Show final summary
    Show-FinalSummary

    Write-Host "`n✓ Script execution complete" -ForegroundColor Green
}

# Execute main function with error handling
try {
    Main
}
catch {
    Write-Error "Unexpected error occurred: $($_.Exception.Message)"
    Write-Host "`nStack Trace:" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    
    Show-Notification -Message "An unexpected error occurred:`n`n$($_.Exception.Message)" -Type Error
    
    exit 1
}

exit 0
