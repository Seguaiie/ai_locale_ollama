# Projet 3 – Ollama en local

## Lancer le setup
Double-clique **`lancer-setup.bat`**. Le script :

1. Met les modèles dans `models\` sur F: (variable `OLLAMA_MODELS`) pour ne pas remplir C:
2. Installe Ollama via winget s'il n'est pas déjà là
3. Redémarre le serveur (`http://localhost:11434`)
4. Télécharge le modèle de base (`qwen3:4b` par défaut, ~2,5 Go)
5. Crée le modèle perso `assistant-projet` depuis le `Modelfile`
6. Crée un `.venv` Python avec la lib `ollama`
7. Fait un test

Changer de modèle :
```powershell
.\lancer-setup.bat -Model "gemma3:4b"
```
> Vérifie le nom exact du tag sur https://ollama.com/library avant de le passer.

## Choisir un modèle selon ta carte graphique
| VRAM | Taille conseillée | Exemples |
|---|---|---|
| Pas de GPU / ≤ 4 Go | 1–3B | `llama3.2:3b`, `gemma3:1b` |
| 6–8 Go | 4–8B | `llama3.1:8b`, `gemma3:4b`, `qwen3:8b` |
| 12–16 Go | 12–20B | `gemma3:12b`, `gpt-oss:20b` |
| 24 Go+ | 27–32B | `gemma3:27b`, `qwen3:32b` |

## Mode jeu / mode IA
- **`mode-jeu.bat`** : décharge les modèles et ferme Ollama, ce qui libère la carte graphique et la RAM.
- **`mode-ia.bat`** : relance Ollama.
- `.\ollama-control.ps1 status` : affiche l'état actuel.

Ollama **ne démarre plus avec Windows** : les scripts retirent le démarrage automatique (même si une mise à jour le remet). Pour le réactiver : `.\ollama-control.ps1 autostart-on`.

Astuce : clic droit sur un `.bat` → *Envoyer vers → Bureau (créer un raccourci)*.

## Commandes utiles
```powershell
ollama list                    # modèles installés
ollama run assistant-projet    # discuter dans le terminal
ollama pull <modele>           # télécharger un modèle
ollama rm <modele>             # supprimer un modèle
ollama ps                      # modèles chargés en mémoire (+ GPU/CPU)
```

## Depuis Python
```powershell
.venv\Scripts\python test_ollama.py
```

## API
- API native : `POST http://localhost:11434/api/chat`
- Compatible OpenAI : `http://localhost:11434/v1` (n'importe quelle clé API, ex. `ollama`)

## Personnaliser
Modifie le `SYSTEM` / les `PARAMETER` dans `Modelfile`, puis :
```powershell
ollama create assistant-projet -f Modelfile
```
