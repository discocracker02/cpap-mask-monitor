"""
Kasa plug adapter — TP-Link Kasa KP115, EP25, KP125M
Requires: pip install python-kasa
Tested: KP115 (untested on real hardware — community validation needed)

Note: Only Kasa plugs with energy monitoring work (KP115, EP25, KP125M).
      KP105, HS103 and other basic plugs do NOT have energy monitoring.
"""

from plugs.base_adapter import BasePlugAdapter


class KasaAdapter(BasePlugAdapter):
    """
    Adapter for TP-Link Kasa energy monitoring plugs.

    Config fields required:
      kasa.ip — Local IP of the plug

    Optional:
      kasa.username — Kasa account email (required for newer KLAP protocol plugs)
      kasa.password — Kasa account password (required for newer KLAP protocol plugs)

    Note: Older Kasa plugs (pre-2021) work without credentials.
          Newer plugs require a Kasa account.
    """

    def __init__(self, config: dict):
        try:
            from kasa import Discover, Module
            from kasa.credentials import Credentials
        except ImportError:
            raise ImportError(
                "python-kasa library not found. Install it with: pip install python-kasa"
            )

        kasa_cfg = config.get("kasa", {})
        self._ip       = kasa_cfg["ip"]
        self._username = kasa_cfg.get("username")
        self._password = kasa_cfg.get("password")
        self._device   = None

    async def _connect(self):
        from kasa import Discover, Module
        credentials = None
        if self._username and self._password:
            from kasa.credentials import Credentials
            credentials = Credentials(self._username, self._password)
        self._device = await Discover.discover_single(
            self._ip,
            credentials=credentials
        )
        await self._device.update()

    async def get_watts(self) -> float:
        from kasa import Module
        if self._device is None:
            await self._connect()
        else:
            await self._device.update()

        if Module.Energy not in self._device.modules:
            raise RuntimeError(
                f"This Kasa plug does not support energy monitoring. "
                f"Use KP115, EP25, or KP125M instead."
            )

        energy = self._device.modules[Module.Energy]
        watts  = energy.current_consumption
        if watts is None:
            raise RuntimeError("Energy module returned no data. Check plug connection.")
        return float(watts)
