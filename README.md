# Voicemeeter / Audiodg – Set Affinity

A PowerShell script to set the priority of **Audiodg.exe** and/or **Voicemeeter8x64.exe** to **High** and pin them to a single CPU core.

**Tested on:** Windows 11 (PowerShell)

## Table of Contents
- [Introduction](#introduction)
- [Installation](#installation)
- [Usage](#usage)
- [Important Notes](#important-notes)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Introduction
This script is designed to optimize the performance of **Audiodg.exe** and **Voicemeeter8x64.exe** by setting their process priority to **High** and limiting them to a single CPU core. This can help improve audio processing performance on Windows systems.

## Installation
1. **Download the `.bat` file** from the [Releases](https://github.com/mleem97/voiccemeter8_autostart/releases) page.
2. Press **Win + R**, type `shell:startup`, and press **Enter**.
3. Copy the downloaded `.bat` file into the **Startup** folder that opens.

## Usage
1. On the **first run**, the `.bat` file automatically downloads the corresponding PowerShell script.
2. If you run the script via **Autostart**, you must accept the PowerShell permission prompt (UAC) to allow it to run with the required privileges.
3. The `.bat` file is set up to handle **Voicemeeter**. If you **only** need to adjust **Audiodg**, please use the `.ps1` script for Audiodg directly.

## Important Notes
- You **only need** to download the `.bat` file!
- Changing the priority or affinity of Audiodg.exe may be blocked on some versions of Windows because it runs as a "Protected Process Light". In that case, "Access denied" is possible even for an administrator.

## Troubleshooting
### If PowerShell Denies Permission
1. Change your PowerShell **Execution Policy** to either `RemoteSigned` or `Unrestricted`:
    ```powershell
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
    ```
    or
    ```powershell
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force
    ```
2. Try running the script again. It should now work as intended.

## Contributing
Feel free to reach out if you encounter any issues or have questions! Contributions are welcome. Please open an issue or submit a pull request.

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
