# Voicemeeter / Audiodg – Set Affinity

A PowerShell script to set the priority of **Audiodg.exe** and/or **Voicemeeter8x64.exe** to **High** and pin them to a single CPU core.

**Tested on:** Windows 11 (PowerShell)

---

## How to Use

1. **Download the `.bat` file** from the [Releases].
2. Press **Win + R**, type `shell:startup`, and press **Enter**.
3. Copy the downloaded `.bat` file into the **Startup** folder that opens.

---

## Important Notes

- You **only need** to download the `.bat` file!
- On the **first run**, the `.bat` file automatically downloads the corresponding PowerShell script.
- If you run the script via **Autostart**, you must accept the PowerShell permission prompt (UAC) to allow it to run with the required privileges.
- The `.bat` file is set up to handle **Voicemeeter**. If you **only** need to adjust **Audiodg**, please use the `.ps1` script for Audiodg directly.

---

## If PowerShell Denies Permission

1. Change your PowerShell **Execution Policy** to either `RemoteSigned` or `Unrestricted`:
   
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy #### -Force
   ```
Replace #### with 
```powershell 
RemoteSigned 
```
or 
```powershell 
Unrestricted
```
2. Try running the script again. It should now work as intended.


Feel free to reach out if you encounter any issues or have questions!
