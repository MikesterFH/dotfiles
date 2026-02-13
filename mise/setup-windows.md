# Mise Setup fuer Windows (Git Bash)

## Problem

Wenn `eval "$(mise activate bash)"` in der `.bashrc` gesetzt wird, werden Programme wie `git` nicht mehr gefunden. Dies liegt daran, dass mise den PATH ueberschreibt statt ihn zu erweitern.

## Loesung

Verwende **Shims** statt der vollstaendigen Shell-Integration.

### Installation

1. **Mise installieren** (falls noch nicht geschehen):
   ```bash
   curl https://mise.run | sh
   ```

2. **Konfiguration kopieren**:
   ```bash
   # mise config
   mkdir -p ~/.config/mise
   cp mise/config.toml ~/.config/mise/config.toml

   # bashrc fuer Windows
   cp bash/.bashrc_windows ~/.bashrc
   ```

3. **Shims erstellen**:
   ```bash
   mise reshim
   ```

4. **Terminal neu starten**

### Wie es funktioniert

Statt `mise activate bash` zu verwenden (was den PATH dynamisch aendert), nutzen wir **Shims**:

- Shims sind kleine Wrapper-Skripte in `~/.local/share/mise/shims/`
- Sie leiten Aufrufe an die richtige Tool-Version weiter
- Der PATH wird nur einmal erweitert, nicht ersetzt
- Git Bash Pfade bleiben erhalten

### Tools installieren

```bash
# Node.js installieren
mise use -g node@lts

# Python installieren
mise use -g python@3.12

# Go installieren
mise use -g go@latest

# Verfuegbare Plugins anzeigen
mise plugins ls-remote

# Installierte Tools anzeigen
mise ls
```

### Projekt-spezifische Versionen

Erstelle eine `.mise.toml` im Projektverzeichnis:

```toml
[tools]
node = "18"
python = "3.11"
```

Oder nutze vorhandene Dateien:
- `.nvmrc` fuer Node.js
- `.python-version` fuer Python
- `.tool-versions` (asdf Format)

### Troubleshooting

**Problem: Commands werden nicht gefunden**
```bash
# Shims neu erstellen
mise reshim

# PATH pruefen
echo $PATH | tr ':' '\n' | grep -E "(mise|shims)"
```

**Problem: Falsche Tool-Version**
```bash
# Aktuelle Versionen anzeigen
mise current

# Trust-Einstellungen pruefen
mise trust
```

**Problem: Git Bash Pfade fehlen**
Die `.bashrc_windows` fuegt am Ende kritische Pfade wieder hinzu:
```bash
for critical_path in /mingw64/bin /usr/bin /bin; do
    # ... wird automatisch hinzugefuegt
done
```
