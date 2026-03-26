"""
Tuya plug adapter — any Tuya-compatible energy monitoring plug
Requires: pip install tinytuya
Tested: Untested on real hardware — community validation needed

Compatible plugs (examples):
  Gosund SP111, SP112
  BlitzWolf BW-SHP6, BW-SHP13
  Nous A1T, A1W
  Athom PG01V2 (pre-flashed Tasmota also works via HTTP)
  Any plug listed as "energy monitoring" on the Smart Life / Tuya app

Setup steps (required before use):
  1. Pair plug with Smart Life app
  2. Create Tuya developer account at iot.tuya.com
  3. Link Smart Life account to developer project
  4. Run: python3 -m tinytuya wizard
     This fetches Device ID, IP, and Local Key for all paired devices
  5. Add device_id, local_key, ip, and version to config.json

Note on DPS keys:
  Most Tuya energy plugs use DPS key '19' for power in mW/10.
  Some plugs use different keys. If yours reads 0.0W constantly,
  set dps_power_key to the correct key in config.json.
  Run: python3 -m tinytuya scan to inspect your device's DPS keys.
"""

from plugs.base_adapter import BasePlugAdapter


class TuyaAdapter(BasePlugAdapter):
    """
    Adapter for Tuya-compatible energy monitoring plugs.

    Config fields required:
      tuya.ip        — Local IP of the plug
      tuya.device_id — Device ID (from tinytuya wizard)
      tuya.local_key — Local encryption key (from tinytuya wizard)

    Optional:
      tuya.version      — Protocol version (default: 3.3, try 3.4 if 3.3 fails)
      tuya.dps_power_key — DPS key for power reading (default: '19')
      tuya.power_divisor — Divisor for raw value to watts (default: 10)
    """

    def __init__(self, config: dict):
        try:
            import tinytuya
        except ImportError:
            raise ImportError(
                "tinytuya library not found. Install it with: pip install tinytuya"
            )

        tuya_cfg = config.get("tuya", {})
        self._ip         = tuya_cfg["ip"]
        self._device_id  = tuya_cfg["device_id"]
        self._local_key  = tuya_cfg["local_key"]
        self._version    = float(tuya_cfg.get("version", 3.3))
        self._power_key  = str(tuya_cfg.get("dps_power_key", "19"))
        self._divisor    = float(tuya_cfg.get("power_divisor", 10))

    async def get_watts(self) -> float:
        import tinytuya
        import asyncio

        # tinytuya is synchronous — run in executor to avoid blocking event loop
        loop = asyncio.get_event_loop()
        watts = await loop.run_in_executor(None, self._poll)
        return watts

    def _poll(self) -> float:
        import tinytuya

        d = tinytuya.OutletDevice(
            dev_id=self._device_id,
            address=self._ip,
            local_key=self._local_key,
            version=self._version
        )
        d.set_socketTimeout(5)

        data = d.status()

        if not data or "dps" not in data:
            raise RuntimeError(f"No data from Tuya plug. Raw response: {data}")

        dps = data["dps"]

        if self._power_key not in dps:
            available_keys = list(dps.keys())
            raise RuntimeError(
                f"DPS key '{self._power_key}' not found. "
                f"Available keys: {available_keys}. "
                f"Set tuya.dps_power_key in config.json to the correct key."
            )

        raw_value = dps[self._power_key]
        watts     = float(raw_value) / self._divisor
        return watts
