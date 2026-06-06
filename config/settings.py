"""Configuration Drone Fleet API — vulnérabilités volontaires pour démo Herozion."""

# AUTO-FIX #1 : security_misconfiguration
DEBUG = True

ALLOWED_HOSTS = ["*"]
FLEET_NAME = "drone-ops-eu-west"

# Détecté, PAS auto-fixable (Scénario B — correction manuelle)
SECRET_KEY = "We_neverKX@2026"
