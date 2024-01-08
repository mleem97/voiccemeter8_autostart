# Voicemeter / Audiodg - Set Affinity 
Powershell Script to set priority of process "Audiodg" and/or "Voicemeter8x64" to High and set it to run on a single core.

Tested on Powershell 7 @ Windows 11


## How to Use?

- Download desired Script to a location of your choosing.
- Start PowerShell as Administrator
- Set Group RemoteSigned or Unrestricted
```powershell
Set-ExecutionPolicy -ExecutionPolicy #### -force
```
- Instead of #### use RemoteSigned or Unrestricted
- The Script should work.
    

