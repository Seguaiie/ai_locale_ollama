# =====================================================================
#  Controle d'Ollama : couper pour jouer / relancer pour l'IA
#  .\ollama-control.ps1 stop     -> decharge les modeles et ferme tout
#  .\ollama-control.ps1 start    -> relance Ollama
#  .\ollama-control.ps1 status   -> etat actuel
# =====================================================================
param(
    [ValidateSet("stop", "start", "status")]
    [string]$Action = "status"
)

$OllamaDir = Join-Path $env:LOCALAPPDATA "Programs\Ollama"
$Ollama    = Join-Path $OllamaDir "ollama.exe"
$TrayApp   = Join-Path $OllamaDir "ollama app.exe"
$cmd = Get-Command ollama -ErrorAction SilentlyContinue
if ($cmd) { $Ollama = $cmd.Source }

function Test-Server {
    try {
        $c = New-Object System.Net.Sockets.TcpClient
        $ok = $c.ConnectAsync("127.0.0.1", 11434).Wait(1000)
        $c.Close(); return $ok
    } catch { return $false }
}

function Get-OllamaProcs { Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -like "ollama*" } }

switch ($Action) {

    "stop" {
        Write-Host "Mode JEU : arret d'Ollama..." -ForegroundColor Cyan
        # 1. Decharger proprement les modeles de la carte graphique
        if (Test-Server) {
            try {
                $running = (Invoke-RestMethod "http://127.0.0.1:11434/api/ps" -TimeoutSec 3).models
                foreach ($m in $running) {
                    & $Ollama stop $m.name 2>$null
                    Write-Host "  Modele decharge : $($m.name)"
                }
            } catch { }
        }
        # 2. Fermer l'app, le serveur et les runners
        Get-OllamaProcs | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        if (Get-OllamaProcs) {
            Write-Host "  [!] Certains processus Ollama tournent encore." -ForegroundColor Yellow
        } else {
            Write-Host "  [OK] Ollama est ferme, carte graphique et RAM liberees. Bon jeu !" -ForegroundColor Green
        }
    }

    "start" {
        Write-Host "Mode IA : demarrage d'Ollama..." -ForegroundColor Cyan
        if (Test-Server) { Write-Host "  [OK] Ollama tourne deja." -ForegroundColor Green; break }
        $models = [Environment]::GetEnvironmentVariable("OLLAMA_MODELS", "User")
        if ($models) { $env:OLLAMA_MODELS = $models }
        if (Test-Path $TrayApp) { Start-Process $TrayApp }
        else { Start-Process $Ollama -ArgumentList "serve" -WindowStyle Hidden }

        for ($i = 0; $i -lt 30; $i++) {
            if (Test-Server) { break }
            if ($i -eq 15) { Start-Process $Ollama -ArgumentList "serve" -WindowStyle Hidden }
            Start-Sleep -Seconds 1
        }
        if (Test-Server) { Write-Host "  [OK] Ollama est pret sur http://127.0.0.1:11434" -ForegroundColor Green }
        else { Write-Host "  [!] Ollama ne repond pas. Ouvre-le depuis le menu Demarrer." -ForegroundColor Yellow }
    }

    "status" {
        if (Test-Server) {
            Write-Host "Ollama : EN MARCHE" -ForegroundColor Green
            & $Ollama ps
        } elseif (Get-OllamaProcs) {
            Write-Host "Ollama : processus presents mais serveur injoignable" -ForegroundColor Yellow
        } else {
            Write-Host "Ollama : ARRETE" -ForegroundColor Red
        }
    }
}
