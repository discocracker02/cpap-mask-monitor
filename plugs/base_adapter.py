"""
Base plug adapter — all plug implementations inherit from this.
To add a new plug type, create a new file in this directory
and implement the get_watts() method.
"""

from abc import ABC, abstractmethod


class BasePlugAdapter(ABC):
    """Abstract base class for all smart plug adapters."""

    @abstractmethod
    async def get_watts(self) -> float:
        """
        Return current power consumption in watts.
        Must return a float. Raise an exception on connection failure.
        """
        raise NotImplementedError

    @classmethod
    def from_config(cls, config: dict) -> "BasePlugAdapter":
        """
        Factory method — returns correct adapter based on config plug_type.

        Supported plug_type values:
          tapo    — TP-Link Tapo P110, P115 (default)
          kasa    — TP-Link Kasa KP115, EP25, KP125M
          tuya    — Any Tuya-compatible energy monitoring plug
        """
        plug_type = config.get("plug_type", "tapo").lower()

        if plug_type == "tapo":
            from plugs.tapo_adapter import TapoAdapter
            return TapoAdapter(config)
        elif plug_type == "kasa":
            from plugs.kasa_adapter import KasaAdapter
            return KasaAdapter(config)
        elif plug_type == "tuya":
            from plugs.tuya_adapter import TuyaAdapter
            return TuyaAdapter(config)
        else:
            raise ValueError(
                f"Unknown plug_type '{plug_type}'. "
                f"Supported: tapo, kasa, tuya"
            )
