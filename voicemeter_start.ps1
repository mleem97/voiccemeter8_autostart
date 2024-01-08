# Überprüfe Administratorrechte
$isElevated = ([Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544"
if (-not $isElevated) {
    Write-Host "Das Skript erfordert Administratorrechte. Starte das Skript erneut als Administrator."

    # Pfad zur PowerShell-Exe-Datei
    $powershellExePath = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"

    # Starte das Skript erneut mit Administratorrechten
    Start-Process -FilePath $powershellExePath -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`"" -Verb RunAs

    # Beende das aktuelle nicht erhöhte Skript
    exit
}

# Funktion zum Überprüfen, ob ein Prozess läuft
function Test-ProcessRunning($processName) {
    return Get-Process -name $processName -ErrorAction SilentlyContinue
}

# Setze die Priorität und Affinität für "Audiodg.exe"
$audioProcess = Get-Process -Name Audiodg

if ($audioProcess) {
    $audioProcess.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High
    $audioProcess.ProcessorAffinity = 1
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show("Audiodg wurde angepasst.", "Info", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
} else {
# Der Rückgabewert ist 1, führe andere Aktionen aus
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show("Audiodg wurde nicht angepasst.", "Info", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}

# Überprüfe, ob "voicemeeter8x64.exe" läuft
$voicemeeterProcessName = "voicemeeter8x64.exe"
$voicemeeterProcess = Test-ProcessRunning $voicemeeterProcessName

if ($voicemeeterProcess) {
    # Setze die Priorität und Affinität für "voicemeeter8x64.exe"
    $voicemeeterProcess.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High
    $voicemeeterProcess.ProcessorAffinity = 1
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show("Voicemeter wurde angepasst.", "Info", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
} else {
    # Starte "voicemeeter8x64.exe", falls nicht gestartet
    Start-Process -FilePath "C:\Program Files (x86)\VB\Voicemeeter\voicemeeter8x64.exe"
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show("Voicemeter wurde gestartet.", "Info", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}

# Nach erfolgreicher Ausführung:
# Zeige ein Erfolgsmeldungsfenster an
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.MessageBox]::Show(":) Alles Gucci", "Erfolg", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
# Rückgabewert 0 für Erfolg
return 0

