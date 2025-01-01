#requires -version 3

<#
.SYNOPSIS
  Skript zur Überprüfung von Adminrechten, Setzen von Prozesspriorität und CPU-Affinität für Audiodg.exe.

.DESCRIPTION
  - Prüft zuerst, ob das Skript mit erhöhten Rechten läuft.
  - Wenn nicht, wird das Skript automatisch mit Administratorrechten neu gestartet.
  - Zeigt einen Countdown-Fortschrittsbalken an.
  - Setzt die Prozesspriorität und CPU-Affinität für Audiodg.exe (falls erlaubt).
  - Fängt mögliche Fehler in try/catch ab.
  - Optional: wartet nach dem Countdown auf einen Tastendruck.

.NOTES
  Bei Audiodg.exe kann es sein, dass die Prioritäts- oder Affinitätsänderung blockiert wird, weil dieser Prozess
  auf manchen Windows-Versionen als "Protected Process Light" läuft. In dem Fall ist auch als Admin "Zugriff verweigert" möglich.

#>

# ---------------------------------------------
# 1) Überprüfung Administratorrechte
# ---------------------------------------------
Write-Verbose "Prüfe Administratorrechte..."
$isElevated = ([Security.Principal.WindowsIdentity]::GetCurrent()).Groups -match "S-1-5-32-544"
if (-not $isElevated) {
    Write-Host "Das Skript erfordert Administratorrechte. Es wird neu als Administrator gestartet..."

    $powershellExePath = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    Start-Process -FilePath $powershellExePath -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`"" -Verb RunAs
    
    # Das aktuelle Skript beenden, da es nicht erhöht ist
    exit
}

Write-Host "Skript wird mit Administratorrechten ausgeführt..."

# ---------------------------------------------
# 2) Funktion: Countdown anzeigen
# ---------------------------------------------
function Start-Countdown {
    param(
        [Parameter(Mandatory=$true)]
        [int]
        $SleepIntervalSec
    )

    Write-Host "Starte Countdown für $SleepIntervalSec Sekunden..."

    foreach ($step in 1..$SleepIntervalSec) {
        Write-Progress `
            -Activity "All Settings Applied" `
            -Status "Countdown läuft..." `
            -SecondsRemaining ($SleepIntervalSec - $step) `
            -PercentComplete ($step / $SleepIntervalSec * 100)

        Start-Sleep -Seconds 1
    }
    # Optional: Warten auf Tastendruck
    # Hier auskommentiert lassen, falls nicht gewünscht:
    # Write-Host "Drücke eine beliebige Taste, um fortzufahren..."
    # [System.Console]::ReadKey() | Out-Null
}

# ---------------------------------------------
# 3) Funktion: Prozess-Check
#    (Wird im Beispiel unten nicht zwingend genutzt,
#     kann aber als Hilfsfunktion dienen)
# ---------------------------------------------
function Test-ProcessRunning {
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $ProcessName
    )
    # Gibt TRUE zurück, wenn Prozess existiert, sonst FALSE
    $proc = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
    return $proc -ne $null
}

# ---------------------------------------------
# 4) Setze die Priorität und Affinität für Audiodg.exe
# ---------------------------------------------
Write-Host "`nVersuche, Audiodg.exe zu finden..."
$audioProcess = Get-Process -Name Audiodg -ErrorAction SilentlyContinue

if ($audioProcess) {
    # Falls mehrere Instanzen zurückkommen, nur den ersten nehmen
    if ($audioProcess.Count -gt 1) {
        Write-Host "Mehrere Instanzen von Audiodg.exe gefunden, verwende nur die erste."
        $audioProcess = $audioProcess[0]
    }

    try {
        Write-Host "Setze Prozesspriorität auf 'High'..."
        $audioProcess.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High

        Write-Host "Setze CPU-Affinität auf nur CPU0..."
        # Wir geben explizit einen IntPtr an
        $audioProcess.ProcessorAffinity = [System.IntPtr]1

        Write-Host "Priorität und Affinität wurden (sofern erlaubt) erfolgreich gesetzt."
    }
    catch {
        Write-Warning "Fehler beim Setzen der Priorität oder Affinität: $($_.Exception.Message)"
    }

    # Countdown anzeigen
    Start-Countdown -SleepIntervalSec 10

} else {
    Write-Host "Der Prozess 'Audiodg.exe' wurde nicht gefunden oder läuft derzeit nicht."
}

# ---------------------------------------------
# 5) Skript-Ende, Exit-Code 0 für Erfolg
# ---------------------------------------------
Write-Host "`nSkript fertig. Exit-Code = 0"
return 0
