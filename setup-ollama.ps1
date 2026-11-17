# =====================================================================
#  Setup Ollama - Projet 3 : exploration des nouvelles technos
#  Usage :  clic droit > "Executer avec PowerShell"   (ou lancer-setup.bat)
#           .\setup-ollama.ps1 -Model "llama3.2:3b"
# =====================================================================
param(
    [string]$Model = "qwen3:4b",          # modele de base a telecharger
    [string]$CustomName = "assistant-projet", # nom du modele perso (Modelfile)
    [switch]$SkipPython                       # ne pas creer l'environnement Python
)

$ErrorActionPreference = "Stop"
$Root      = $PSScriptRoot
$ModelsDir = Join-Path $Root "models"

function Step($msg) { Write-Host "`n=== $msg ===" -ForegroundColor Cyan }
function Ok($msg)   { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "  [!]  $msg" -ForegroundColor Yellow }

# ---------------------------------------------------------------------
Step "1. Dossier des modeles sur F: (evite de remplir C:)"
New-Item -ItemType Directory -Force -Path $ModelsDir | Out-Null
[Environment]::SetEnvironmentVariable("OLLAMA_MODELS", $ModelsDir, "User")
$env:OLLAMA_MODELS = $ModelsDir
Ok "OLLAMA_MODELS = $ModelsDir"

# ---------------------------------------------------------------------
Step "2. Installation d'Ollama"
function Find-Ollama {
    $cmd = Get-Command ollama -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $default = Join-Path $env:LOCALAPPDATA "Programs\Ollama\ollama.exe"
    if (Test-Path $default) { return $default }
    return $null
}

$Ollama = Find-Ollama
if (-not $Ollama) {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "  Installation via winget..."
        winget install --id Ollama.Ollama -e --accept-source-agreements --accept-package-agreements
        $env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User")
        $Ollama = Find-Ollama
    }
    if (-not $Ollama) {
        Warn "Ollama introuvable. Installe-le depuis https://ollama.com/download/windows puis relance ce script."
        Start-Process "https://ollama.com/download/windows"
        exit 1
    }
}
Ok "Ollama : $Ollama"
& $Ollama --version

# ---------------------------------------------------------------------
Step "3. (Re)demarrage du serveur pour prendre en compte OLLAMA_MODELS"
Get-Process -Name "ollama app", "ollama" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2
$TrayApp = Join-Path (Split-Path $Ollama) "ollama app.exe"
if (Test-Path $TrayApp) { Start-Process $TrayApp }
else { Start-Process $Ollama -ArgumentList "serve" -WindowStyle Hidden }

function Test-Server {
    try {
        $c = New-Object System.Net.Sockets.TcpClient
        $ok = $c.ConnectAsync("127.0.0.1", 11434).Wait(1000)
        $c.Close(); return $ok
    } catch { return $false }
}

Write-Host "  Attente du serveur" -NoNewline
$up = $false
for ($i = 0; $i -lt 40; $i++) {
    if (Test-Server) { $up = $true; break }
    # Si l'app n'a pas lance le serveur apres 15 s, on le lance directement
    if ($i -eq 15) { Start-Process $Ollama -ArgumentList "serve" -WindowStyle Hidden }
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 1
}
Write-Host ""
if (-not $up) { Warn "Le serveur ne repond pas sur http://127.0.0.1:11434 - relance le script."; exit 1 }
Ok "Serveur en ligne sur http://localhost:11434"

# ---------------------------------------------------------------------
Step "4. Telechargement du modele $Model"
& $Ollama pull $Model
Ok "Modele $Model pret"

# ---------------------------------------------------------------------
Step "5. Creation du modele perso '$CustomName' depuis le Modelfile"
$Modelfile = Join-Path $Root "Modelfile"
if (Test-Path $Modelfile) {
    $tmp = Join-Path $env:TEMP "Modelfile.projet"
    (Get-Content $Modelfile) -replace '^FROM .*', "FROM $Model" | Set-Content $tmp -Encoding UTF8
    & $Ollama create $CustomName -f $tmp
    Ok "Modele perso '$CustomName' cree"
} else { Warn "Pas de Modelfile, etape sautee" }

# ---------------------------------------------------------------------
if (-not $SkipPython) {
    Step "6. Environnement Python (.venv)"
    $py = Get-Command python -ErrorAction SilentlyContinue
    if ($py) {
        $venv = Join-Path $Root ".venv"
        if (-not (Test-Path $venv)) { & python -m venv $venv }
        & (Join-Path $venv "Scripts\python.exe") -m pip install --upgrade pip -q
        & (Join-Path $venv "Scripts\pip.exe") install -r (Join-Path $Root "requirements.txt") -q
        Ok "Python pret : .venv\Scripts\python test_ollama.py"
    } else {
        Warn "Python introuvable - installe-le (winget install Python.Python.3.12) puis relance."
    }
}

# ---------------------------------------------------------------------
Step "7. Test rapide"
& $Ollama list
& $Ollama run $CustomName "Presente-toi en une phrase."

# ---------------------------------------------------------------------
Step "8. Pas de demarrage automatique avec Windows"
& (Join-Path $Root "ollama-control.ps1") autostart-off

Write-Host "`nTout est pret ! Lance 'ollama run $CustomName' pour discuter." -ForegroundColor Green
