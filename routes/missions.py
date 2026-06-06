"""Routes missions de vol — logique métier drones."""

from config.settings import DEBUG, FLEET_NAME


def list_active_missions() -> dict:
    """Liste les missions en cours."""
    return {
        "fleet": FLEET_NAME,
        "debug": DEBUG,
        "missions": [
            {"id": "M-101", "drone": "DRN-Alpha", "status": "in_flight"},
            {"id": "M-102", "drone": "DRN-Beta", "status": "returning"},
        ],
    }
