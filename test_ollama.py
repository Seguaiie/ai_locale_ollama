"""Test rapide d'Ollama depuis Python.

Usage :  .venv\\Scripts\\python test_ollama.py
         .venv\\Scripts\\python test_ollama.py llama3.2:3b
"""
import sys

import ollama

MODEL = sys.argv[1] if len(sys.argv) > 1 else "assistant-projet"


def main() -> None:
    # 1. Modeles installes
    print("Modeles installes :")
    for m in ollama.list().models:
        print(f"  - {m.model}  ({m.size / 1e9:.1f} Go)")

    # 2. Chat en streaming
    print(f"\n--- Chat avec {MODEL} ---")
    stream = ollama.chat(
        model=MODEL,
        messages=[{"role": "user", "content": "Explique ce qu'est Ollama en 3 phrases."}],
        stream=True,
    )
    for chunk in stream:
        print(chunk.message.content, end="", flush=True)
    print()

    # 3. Petite boucle interactive
    print("\n(Tape 'q' pour quitter)")
    history = []
    while True:
        q = input("\nToi > ").strip()
        if q.lower() in {"q", "quit", "exit"}:
            break
        history.append({"role": "user", "content": q})
        reply = ""
        print("IA  > ", end="")
        for chunk in ollama.chat(model=MODEL, messages=history, stream=True):
            reply += chunk.message.content
            print(chunk.message.content, end="", flush=True)
        print()
        history.append({"role": "assistant", "content": reply})


if __name__ == "__main__":
    main()
