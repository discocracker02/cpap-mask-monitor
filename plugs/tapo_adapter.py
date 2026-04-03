"""
Tapo plug adapter — TP-Link Tapo P110, P115
Requires: pip install tapo
Tested: Tapo P110, P115
"""

from plugs.base_adapter import BasePlugAdapter


class TapoAdapter(BasePlugAdapter):
    """
    Adapter for TP-Link Tapo energy monitoring plugs (P110, P115).

    Config fields required:
      tapo.email    — Tapo account email
      tapo.password — Tapo account password
      tapo.ip       — Local IP of the plug
    """

    def __init__(self, config: dict):
        try:
            from tapo import ApiClient
        except ImportError:
            raise ImportError(
                "tapo library not found. Install it with: pip install tapo"
            )

        tapo_cfg = config.get("tapo", {})
        self._email    = tapo_cfg["email"]
        self._password = tapo_cfg["password"]
        self._ip       = tapo_cfg["ip"]
        self._client   = ApiClient(self._email, self._password)

    async def get_watts(self) -> float:
        device = await self._client.p110(self._ip)
        info   = await device.get_current_power()
        return float(info.current_power)
