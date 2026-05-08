from __future__ import annotations

import base64
import hashlib
import hmac
import json
import time


def _base64url_encode(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("ascii")


def generate_zai_token(api_key: str, exp_seconds: int = 3600) -> str:
    """Generate a Z.AI / Zhipu AI JWT token from an API key.

    The API key must be in the ``id.secret`` format (two parts separated by a dot).
    If the key does not contain a dot it is returned as-is (raw API key mode).
    """
    if "." not in api_key:
        # Raw API key mode – no JWT signing required
        return api_key

    key_id, secret = api_key.split(".", 1)
    now_ms = int(time.time() * 1000)

    header = json.dumps({"alg": "HS256", "sign_type": "SIGN"}, separators=(",", ":"))
    payload = json.dumps(
        {
            "api_key": key_id,
            "exp": now_ms + exp_seconds * 1000,
            "timestamp": now_ms,
        },
        separators=(",", ":"),
    )

    signing_input = (
        f"{_base64url_encode(header.encode())}.{_base64url_encode(payload.encode())}"
    )
    signature = hmac.new(
        secret.encode(), signing_input.encode(), hashlib.sha256
    ).digest()

    return f"{signing_input}.{_base64url_encode(signature)}"
