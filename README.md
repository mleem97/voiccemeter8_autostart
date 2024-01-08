# Voicemeter / Audiodg - Set Affinity 
Powershell Script to set priority of process "Audiodg" and/or "Voicemeter8x64" to High and set it to run on a single core.

Tested on Powershell @ Windows 11

## How to Use?

- Download bat file from releases.
- Press Win + R and enter shell:startup
- Place Bat file into the folder that opens.

## IMPORTANT!
- You only need to download the bat file!
- On first run the File downloads the Script automatically.
- If you run the Script via Autostart, you need to Accept the Window that gives Powershell the Permission to run.
- The Bat File ONLY runs the voicemeter Version! If you only need it for audiodg, use the .ps1 version for Audiodg!

## If Powershell tells you you have no permission:
- Set Group RemoteSigned or Unrestricted
```powershell
Set-ExecutionPolicy -ExecutionPolicy #### -force
```
- Instead of #### use RemoteSigned or Unrestricted
- The Script should work.



