"""Connexion base de données flotte de drones."""

# Scénario B — sensitive_data_exposure (PAS d'auto-fix, correction manuelle)
db_password = "wegonna2026@dev"
DB_HOST = "postgres.drone-ops.internal"
DB_USER = "drone_app"


def get_connection_string() -> str:
    return f"postgresql://{DB_USER}:{db_password}@{DB_HOST}:5432/drone_fleet"
