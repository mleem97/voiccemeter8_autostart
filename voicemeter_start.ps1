#requires -version 3

<#
.SYNOPSIS
  Angepasstes Skript zum Überprüfen, Anpassen oder Starten bestimmter Prozesse.
.DESCRIPTION
  - Enthält eine Funktion, um zu prüfen, ob ein Prozess läuft.
  - Ändert Prozesspriorität und CPU-Affinität für Audiodg.exe und Voicemeeter (falls vorhanden).
  - Startet Voicemeeter, wenn es nicht läuft.
  - Zeigt MessageBoxen mit Statusinformationen.
.NOTES
  Bitte als Administrator ausführen, da Set-ProcessPriority etc. sonst scheitern kann.
#>

# Nur einmal deklarieren, statt mehrfach
Add-Type -AssemblyName System.Windows.Forms

# Funktion zum Überprüfen, ob ein Prozess läuft
function Test-ProcessRunning {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProcessName
    )
    # Gibt die Prozessobjekte zurück (oder $null), wenn kein Prozess läuft.
    return Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
}

# ------------------------------------------------------
# 1) Audiodg.exe prüfen und ggf. anpassen
# ------------------------------------------------------
try {
    # Suche Audiodg.exe
    $audioProcess = Get-Process -Name Audiodg -ErrorAction SilentlyContinue
} catch {
    [System.Windows.Forms.MessageBox]::Show("Fehler beim Abfragen von Audiodg.exe: $($_.Exception.Message)", 
        "Fehler", 
        [System.Windows.Forms.MessageBoxButtons]::OK, 
        [System.Windows.Forms.MessageBoxIcon]::Error)
    # Early return (oder einfach weitermachen; hier je nach Bedarf)
    return 1
}

if ($audioProcess) {
    # Falls mehrere Instanzen zurückkommen, nimm nur den ersten
    if ($audioProcess.Count -gt 1) {
        $audioProcess = $audioProcess[0]
    }

    try {
        $audioProcess.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High
        # Affinität wird hier auf CPU0 gesetzt
        $audioProcess.ProcessorAffinity = [System.IntPtr]1

        [System.Windows.Forms.MessageBox]::Show(
            "Audiodg.exe wurde angepasst.",
            "Info",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Audiodg.exe konnte nicht angepasst werden: $($_.Exception.Message)",
            "Fehler",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}
else {
    # Falls Audiodg gar nicht gefunden wurde
    [System.Windows.Forms.MessageBox]::Show(
        "Audiodg.exe wurde nicht gefunden oder läuft nicht.",
        "Info",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
}

# ------------------------------------------------------
# 2) Voicemeeter8x64.exe prüfen und ggf. anpassen/Starten
# ------------------------------------------------------
$voicemeeterProcessName = "voicemeeter8x64.exe"
$voicemeeterProcess = Test-ProcessRunning -ProcessName $voicemeeterProcessName

if ($voicemeeterProcess) {
    # Falls mehrere Prozesse gefunden, nimm nur den ersten
    if ($voicemeeterProcess.Count -gt 1) {
        $voicemeeterProcess = $voicemeeterProcess[0]
    }

    try {
        $voicemeeterProcess.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High
        $voicemeeterProcess.ProcessorAffinity = [System.IntPtr]1

        [System.Windows.Forms.MessageBox]::Show(
            "Voicemeeter wurde angepasst.",
            "Info",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Voicemeeter konnte nicht angepasst werden: $($_.Exception.Message)",
            "Fehler",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}
else {
    # Starte Voicemeeter, wenn nicht vorhanden
    Start-Process -FilePath "C:\Program Files (x86)\VB\Voicemeeter\voicemeeter8x64.exe"

    [System.Windows.Forms.MessageBox]::Show(
        "Voicemeeter wurde gestartet.",
        "Info",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
}

# ------------------------------------------------------
# Abschluss: Erfolgsmeldung
# ------------------------------------------------------
[System.Windows.Forms.MessageBox]::Show(
    ":) Alles Gucci",
    "Erfolg",
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Information
)

# Erfolgsrückgabe
return 0
