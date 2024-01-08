# Voicemeter / Audiodg - Set Affinity 
Powershell Script to set priority of process "Audiodg" and/or "Voicemeter8x64" to High and set it to run on a single core.

Tested on Powershell 7 @ Windows 11

## How to Use?

- Download desired Script to a location of your choosing.
- Start PowerShell as Administrator
- CD into "C:\Path\To\Script\" 
- Run Script via .\scriptname.ps1

## How to Use? (Autostart)

- Download bat file from releases.
- Press Win + R and enter shell:startup
- Place Bat file into the folder that opens.

## If Powershell tells you you have no permission:
- Set Group RemoteSigned or Unrestricted
```powershell
Set-ExecutionPolicy -ExecutionPolicy #### -force
```
- Instead of #### use RemoteSigned or Unrestricted
- The Script should work.





