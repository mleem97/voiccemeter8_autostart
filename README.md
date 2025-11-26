# Audio Optimizer for Voicemeeter & Audiodg

> Automatically optimize audio processing performance by setting process priority and CPU affinity for Voicemeeter and Windows Audiodg service.

![PowerShell Version](https://img.shields.io/badge/PowerShell-3.0+-blue)
![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D4)
![License](https://img.shields.io/badge/License-MIT-green)

## 🎯 Overview

This PowerShell script optimizes audio performance on Windows by automatically:
- **Starting Voicemeeter** if not already running
- **Setting process priority to High** for both Voicemeeter and Audiodg
- **Pinning both processes to CPU Core 0** for consistent performance
- **Displaying detailed status notifications** with visual feedback

**Tested on:** Windows 10 & 11 with PowerShell 3.0+

---

## 📋 Table of Contents

- [Features](#-features)
- [System Requirements](#-system-requirements)
- [Installation](#-installation)
- [Usage](#-usage)
- [Configuration](#-configuration)
- [Important Notes](#-important-notes)
- [Troubleshooting](#-troubleshooting)
- [Advanced Options](#-advanced-options)
- [Contributing](#-contributing)
- [License](#-license)

---

## ✨ Features

✅ **Dual Process Management**
- Automatically detects and configures Voicemeeter
- Optimizes Windows Audiodg.exe service simultaneously
- Auto-starts Voicemeeter if not running

✅ **Intelligent Retry Logic**
- Automatic process detection with configurable retry attempts
- Handles startup delays gracefully
- Doesn't fail if one process is unavailable

✅ **Visual Feedback**
- GUI message boxes for status notifications
- Color-coded console output for clear feedback
- Detailed operation summary with success/failure indicators

✅ **Robust Error Handling**
- Specific exception handling for different error scenarios
- Graceful degradation if permissions are restricted
- Comprehensive error logging and reporting

✅ **Administrator Privilege Management**
- Automatic elevation to admin rights if needed
- One-click re-execution without manual UAC prompts

---

## 📦 System Requirements

- **Operating System:** Windows 10 or Windows 11
- **PowerShell:** Version 3.0 or higher (built-in on all supported Windows versions)
- **Administrator Privileges:** Required (script will auto-elevate)
- **Voicemeeter:** Installed at default location or custom path configured
- **Dependencies:** Windows Forms library (included in Windows)

---

## 🚀 Installation

### Option 1: Quick Setup (Recommended)

1. **Clone or download the repository**
   ```bash
   git clone https://github.com/yourusername/audio-optimizer.git
   cd audio-optimizer
   ```

2. **Save the script**
   - Place `Start-VoicemeeterOptimized.ps1` in a convenient location (e.g., `C:\Scripts\`)

3. **Enable Execution Policy** (if needed)
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
   ```

### Option 2: Task Scheduler (Auto-Run)

1. Save the script to a permanent location: `C:\Scripts\Start-VoicemeeterOptimized.ps1`

2. Open **Task Scheduler** (press `Win + R`, type `taskschd.msc`)

3. **Create a new task:**
   - **Name:** `Audio Optimizer`
   - **Description:** Optimize Voicemeeter and Audiodg at startup
   - **Trigger:** At system startup
   - **Action:** Start a program
     - **Program:** `powershell.exe`
     - **Arguments:** `-NoProfile -ExecutionPolicy Bypass -File "C:\Scripts\Start-VoicemeeterOptimized.ps1"`
   - **Additional:** Check ✓ "Run with highest privileges"

### Option 3: Startup Folder

1. Save the script to `C:\Scripts\Start-VoicemeeterOptimized.ps1`

2. Create a shortcut or batch file in the Startup folder:
   - Press `Win + R`, type `shell:startup`
   - Create a `.bat` file with:
     ```batch
     @echo off
     powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Scripts\Start-VoicemeeterOptimized.ps1"
     ```

---

## 💻 Usage

### Basic Execution

Run the script from PowerShell:
```powershell
.\Start-VoicemeeterOptimized.ps1
```

The script will:
1. ✓ Check for administrator privileges (auto-elevate if needed)
2. ✓ Search for Audiodg.exe
3. ✓ Check if Voicemeeter is running
4. ✓ Start Voicemeeter if not found
5. ✓ Apply High priority to both processes
6. ✓ Pin both to CPU Core 0
7. ✓ Display summary of operations

### With Verbose Output

For detailed troubleshooting information:
```powershell
.\Start-VoicemeeterOptimized.ps1 -Verbose
```

### Via Command Line

Direct execution without opening PowerShell ISE:
```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Scripts\Start-VoicemeeterOptimized.ps1"
```

---

## ⚙️ Configuration

All settings are centralized in the `$Script:Config` hashtable at the top of the script. Modify these values to customize behavior:

```powershell
$Script:Config = @{
    AudiodgProcessName      = 'audiodg'
    VoicemeeterProcessName  = 'voicemeeter8x64'
    VoicemeeterExecutable   = 'C:\Program Files (x86)\VB\Voicemeeter\voicemeeter8x64.exe'
    TargetPriority          = [System.Diagnostics.ProcessPriorityClass]::High
    TargetAffinity          = [System.IntPtr]1  # CPU Core 0
    MaxRetryAttempts        = 3
    RetryDelaySeconds       = 2
    VoicemeeterStartupDelay = 3  # Seconds to wait after starting
}
```

### Configuration Options

| Parameter | Default | Description |
|-----------|---------|-------------|
| `AudiodgProcessName` | `'audiodg'` | Windows process name for audio device graph |
| `VoicemeeterProcessName` | `'voicemeeter8x64'` | Voicemeeter process name |
| `VoicemeeterExecutable` | Default install path | Full path to Voicemeeter executable |
| `TargetPriority` | `High` | Process priority level |
| `TargetAffinity` | `1` (CPU Core 0) | CPU core to pin processes to |
| `MaxRetryAttempts` | `3` | Number of process detection retries |
| `RetryDelaySeconds` | `2` | Delay between retries in seconds |
| `VoicemeeterStartupDelay` | `3` | Seconds to wait for Voicemeeter initialization |

**Custom Voicemeeter Path Example:**
```powershell
VoicemeeterExecutable = 'C:\Custom\Path\voicemeeter8x64.exe'
```

**Different CPU Core:**
```powershell
# Pin to CPU Core 1 instead of Core 0
TargetAffinity = [System.IntPtr]2

# Pin to CPU Core 2
TargetAffinity = [System.IntPtr]4

# Pin to CPU Core 3
TargetAffinity = [System.IntPtr]8
```

---

## ⚠️ Important Notes

### Protected Process Light (PPL)
Audiodg.exe runs as a **Protected Process Light** on modern Windows versions. This means:
- ✓ You may still optimize it, but changes might be **partial**
- ⚠️ Priority changes: **May succeed**
- ⚠️ Affinity changes: **May be blocked** even with administrator privileges
- **Status:** This is normal behavior and not an error

### Voicemeeter Installation
- Ensure Voicemeeter is installed at the default location: `C:\Program Files (x86)\VB\Voicemeeter\`
- If installed elsewhere, update the `VoicemeeterExecutable` configuration
- The script will **not fail** if Voicemeeter is not installed, but won't start it

### Administrator Requirements
- This script **requires administrator privileges**
- It will automatically re-execute with elevated rights
- You may see a UAC prompt on first run—this is expected and necessary

### Performance Impact
- Pinning to a single CPU core is **intentional** for audio consistency
- This reduces context switching and improves real-time performance
- Only recommended for dedicated audio workstations

---

## 🔧 Troubleshooting

### PowerShell Execution Policy Error

**Problem:** `cannot be loaded because running scripts is disabled`

**Solution 1: Change Execution Policy**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

**Solution 2: Bypass for One-Time Run**
```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Scripts\Start-VoicemeeterOptimized.ps1"
```

### Script Not Running with Administrator Privileges

**Problem:** UAC prompt appears but script doesn't elevate

**Solution:**
1. Open PowerShell as Administrator manually
2. Execute the script directly:
   ```powershell
   & "C:\Scripts\Start-VoicemeeterOptimized.ps1"
   ```

### Voicemeeter Not Starting

**Problem:** Script says Voicemeeter couldn't be started

**Solutions:**
- Verify Voicemeeter is installed correctly
- Check the configured path in `$Script:Config`
- Ensure the executable file exists at the specified location
- Try starting Voicemeeter manually first

**Check Installation Path:**
```powershell
Test-Path "C:\Program Files (x86)\VB\Voicemeeter\voicemeeter8x64.exe"
```

### Audiodg.exe Not Found

**Problem:** Script reports "audiodg.exe process not found"

**This is normal if:**
- Audio services are temporarily disabled
- No audio devices are connected
- Windows is still initializing at startup

**Solution:** Wait a few seconds and run the script again, or increase `RetryDelaySeconds` in configuration.

### Priority/Affinity Changes Not Applied

**Problem:** Settings show as failed or partial success

**Possible Causes:**
- **Protected Process Light:** Audiodg.exe may block changes
- **Insufficient Permissions:** Ensure script runs as Administrator
- **Process Locked:** Application or driver has exclusive access

**Workarounds:**
- This is often expected behavior for Audiodg.exe
- Try restarting audio services: `Restart-Service -Name audiosrv`
- Check for audio driver conflicts

---

## 🎯 Advanced Options

### Create a Desktop Shortcut

1. Right-click on desktop → **New** → **Shortcut**
2. Enter the target:
   ```
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Scripts\Start-VoicemeeterOptimized.ps1"
   ```
3. Click **Advanced** and check **✓ Run as administrator**

### Schedule Multiple Runs

Create separate Task Scheduler tasks with different triggers:
```powershell
# Trigger 1: At system startup
# Trigger 2: On user logon
# Trigger 3: Every 1 hour (if processes restart)
```

### Automated Logging

Modify the script to log all operations:
```powershell
$LogPath = "C:\Logs\Audio-Optimizer-$(Get-Date -Format 'yyyyMMdd').log"
Start-Transcript -Path $LogPath -Append
# ... script execution ...
Stop-Transcript
```

### Integration with Other Scripts

Source the script functions in another PowerShell script:
```powershell
. "C:\Scripts\Start-VoicemeeterOptimized.ps1"

# Now you can call individual functions:
Optimize-AudiodgProcess
Start-VoicemeeterApplication
```

---

## 🤝 Contributing

We welcome contributions! Here's how to help:

1. **Report Issues**
   - Describe the problem clearly
   - Include your Windows version
   - Provide PowerShell version output: `$PSVersionTable`

2. **Suggest Improvements**
   - Feature requests welcome
   - Open an issue with detailed description

3. **Submit Code**
   - Fork the repository
   - Create a feature branch: `git checkout -b feature/your-feature`
   - Commit changes: `git commit -am 'Add your feature'`
   - Push to branch: `git push origin feature/your-feature`
   - Open a Pull Request

---

## 📝 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

MIT License © 2025 Meyer Media

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limited the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

---

## 📞 Support

- **Issues:** Open an issue on GitHub

---

## 🔗 Related Resources

- [Voicemeeter Official](https://vb-audio.com/Voicemeeter/)
- [Windows Process Priority](https://docs.microsoft.com/en-us/windows/win32/procthread/process-priority-class)
- [PowerShell Documentation](https://docs.microsoft.com/en-us/powershell/)
- [Task Scheduler Guide](https://docs.microsoft.com/en-us/windows/win32/taskschd/task-scheduler-start-page)

---

**Version:** 2.0  
**Last Updated:** November 26, 2025  
**Maintainer:** @mleem97
