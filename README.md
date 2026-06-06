# Drone — Démo Herozion

API de gestion de flotte de drones (missions, télémétrie, pilotes) avec vulnérabilités **volontaires** pour démontrer Herozion CLI.

## Objectif

| Scénario | Contenu | Action démo |
|----------|---------|-------------|
| **A — Auto-fix** | 3 patterns Python (L1 regex) | `herozion fix N` / `herozion fix-all --yes` |
| **B — Manuel** | Secrets en dur | Présentateur corrige à la main → `os.getenv()` / `process.env.*` |

## Structure

```
drone/
├── config/settings.py              # AUTO-FIX #1 : DEBUG = True
├── services/telemetry_client.py    # AUTO-FIX #2 : verify=False (requests)
├── services/pilot_auth.py          # AUTO-FIX #3 : verify=False (jwt)
├── database/connection.py          # MANUEL : db_password en dur
├── gateway/server.js               # MANUEL : ADMIN_TOKEN en dur
├── routes/missions.py              # Logique métier (propre)
├── .env.example                    # Secret exemple (NE PAS COMMITER)
└── .github/workflows/herozion.yml  # CI scan
```

## Scénario A — Auto-fix (5 étapes)

| Étape | Commande | Message client |
|-------|----------|----------------|
| 1 | `herozion scan .` | Risques HIGH/CRITICAL détectés |
| 2 | Tableau scan | Lignes **✓ fix available** → `herozion fix N` |
| 3 | `herozion fix 1` puis 2, 3 | Diff avant/après + confirmation |
| 4 | Ouvrir le fichier | Patch réel sur le disque |
| 5 | `herozion scan .` | Vulnérabilités **Resolved** |

```bash
herozion scan . --output=table

herozion fix 1
herozion fix 2
herozion fix 3
# ou : herozion fix-all --yes

git diff config/settings.py services/telemetry_client.py services/pilot_auth.py

herozion scan . --output=table
```

### Patterns auto-fixables

| Fichier | Pattern | Catégorie Herozion |
|---------|---------|-------------------|
| `config/settings.py` | `DEBUG = True` | `security_misconfiguration` |
| `services/telemetry_client.py` | `requests.get(..., verify=False)` | `man_in_the_middle` |
| `services/pilot_auth.py` | `jwt.decode(..., verify=False)` | `broken_authentication` |

## Scénario B — Correction manuelle

Herozion **détecte** mais **ne corrige pas** automatiquement :

| Fichier | Secret en dur | Correction attendue |
|---------|---------------|---------------------|
| `database/connection.py` | `db_password = "motdepasse-en-dur"` | `os.getenv("DB_PASSWORD")` |
| `gateway/server.js` | `ADMIN_TOKEN = "token-admin-en-dur"` | `process.env.ADMIN_TOKEN` |
| `config/settings.py` | `SECRET_KEY = "change-me-..."` | variable d'environnement |
| `.env.example` | `DRONE_API_SECRET=...` | modèle, jamais commité en prod |

```bash
herozion scan . --output=table
# Montrer les findings sans ✓ fix available → correction live dans l'IDE
```

## Démarrage local (optionnel)

```bash
pip install -r requirements.txt
npm install
npm start
# Gateway : http://localhost:3000/health
```

## Contraintes Herozion respectées

- Pas de fichiers `test_*.py`
- Pas de `node_modules/`, `dist/`, `.venv/` dans le source de démo
- Fichiers < 80 lignes
- `herozion scan .` → ≥ 3 auto-fixables + ≥ 2 secrets en dur
