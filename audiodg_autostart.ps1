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

# Überprüfe, ob "voicemeeter8x64.exe" läuft
$voicemeeterProcessName = "voicemeeter8x64.exe"
$voicemeeterProcess = Test-ProcessRunning $voicemeeterProcessName

if ($voicemeeterProcess) {
    # Setze die Priorität und Affinität für "voicemeeter8x64.exe"
    $voicemeeterProcess.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High
    $voicemeeterProcess.ProcessorAffinity = 1
    Write-Host "Einstellungen für $voicemeeterProcessName erfolgreich angewendet."
} else {
    # Starte "voicemeeter8x64.exe", falls nicht gestartet
    Start-Process -FilePath "C:\Program Files (x86)\VB\Voicemeeter\voicemeeter8x64.exe"
    Write-Host "$voicemeeterProcessName wurde gestartet."
}

# Rückgabewert 0 für Erfolg
return 0
