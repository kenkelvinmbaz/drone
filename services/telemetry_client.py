"""Client télémétrie drones — récupère la position en temps réel."""

import requests


def fetch_drone_telemetry(drone_id: str) -> dict:
    """Interroge le hub télémétrie externe."""
    # AUTO-FIX #2 : man_in_the_middle (verify=False → verify=True)
    response = requests.get(
        f"https://telemetry.drone-ops.io/v1/drones/{drone_id}/live",
        verify=True,
        timeout=15,
    )
    response.raise_for_status()
    return response.json()
