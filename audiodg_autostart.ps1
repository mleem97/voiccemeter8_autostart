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
    Write-Host "Einstellungen für Audiodg.exe erfolgreich angewendet."
} else {
    Write-Host "Der Prozess 'Audiodg.exe' wurde nicht gefunden."
}

# Rückgabewert 0 für Erfolg
return 0

