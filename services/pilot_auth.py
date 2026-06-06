"""Authentification pilotes — tokens JWT de session de vol."""

import jwt


def decode_pilot_token(token: str, secret: str) -> dict:
    """Décode le JWT pilote et retourne le payload."""
    # AUTO-FIX #3 : broken_authentication (supprime verify=False)
    payload = jwt.decode(
        token,
        secret,
        algorithms=["HS256"],
        verify=True,
    )
    return payload
