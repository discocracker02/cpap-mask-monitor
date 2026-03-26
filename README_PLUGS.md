# Supported Smart Plugs

CPAP Mask Monitor works with three plug ecosystems — Tapo, Kasa, and Tuya-compatible. 
Only plugs with **energy monitoring** (wattage reading) are compatible.

---

## Quick selection guide

| Plug | Country | Buy from | Plug type in config |
|---|---|---|---|
| TP-Link Tapo P110 | Global / India | Amazon, Flipkart | `tapo` |
| TP-Link Tapo P115 | Global / India | Amazon, Flipkart | `tapo` |
| TP-Link Kasa KP115 | US / UK | Amazon | `kasa` |
| TP-Link Kasa EP25 | US | Amazon | `kasa` |
| Wipro WiFi Smart Plug 10A | India | Amazon, Flipkart, offline | `tuya` |
| Wipro WiFi Smart Plug 16A | India | Amazon, Flipkart, offline | `tuya` |
| Havells Coral WiFi Smart Plug 10A | India | Amazon, Flipkart, offline | `tuya` |
| Havells Coral WiFi Smart Plug 16A | India | Amazon, Flipkart, offline | `tuya` |
| Gosund SP111 | Global | Amazon | `tuya` |
| BlitzWolf BW-SHP6 | Global | Amazon | `tuya` |

> **For CPAP machines:** Use a 10A plug. CPAP machines draw 6–20W — well within 10A limits.
> The 16A variants are designed for heavy appliances (AC, geyser, washing machine).

---

## Tested devices

| Device | Status | Notes |
|---|---|---|
| TP-Link Tapo P110 | ✅ Tested | Fully tested. Recommended. |
| TP-Link Tapo P115 | ✅ Tested | Same chip as P110. Works identically. |
| TP-Link Kasa KP115 | 🔄 Code validated | Needs community testing on real hardware. |
| TP-Link Kasa EP25 | 🔄 Code validated | Needs community testing on real hardware. |
| Wipro Smart Plug 10A | 🔄 Code validated | Uses Tuya protocol. See Wipro notes below. |
| Wipro Smart Plug 16A | 🔄 Code validated | Uses Tuya protocol. See Wipro notes below. |
| Havells Coral 10A | 🔄 Code validated | Uses Tuya protocol. Needs community testing. |
| Havells Coral 16A | 🔄 Code validated | Uses Tuya protocol. Needs community testing. |
| Gosund SP111 | 🔄 Code validated | Uses Tuya protocol. Needs community testing. |
| BlitzWolf BW-SHP6 | 🔄 Code validated | Uses Tuya protocol. Needs community testing. |

---

## Tapo plugs (P110, P115)

The default and fully tested option.

**Config:**
```json
{
  "plug_type": "tapo",
  "tapo": {
    "email": "your_tapo_email@example.com",
    "password": "your_tapo_password",
    "ip": "192.168.x.x"
  }
}
```

**Find your plug IP:** Tapo app → tap plug → Settings → Device Info → IP Address

---

## Kasa plugs (KP115, EP25, KP125M)
```bash
pip install python-kasa
```

**Config:**
```json
{
  "plug_type": "kasa",
  "kasa": {
    "ip": "192.168.x.x",
    "username": "your_kasa_email@example.com",
    "password": "your_kasa_password"
  }
}
```

Only KP115, EP25, and KP125M have energy monitoring. KP105 and HS103 do not.

---

## Tuya-compatible plugs (Wipro, Havells, Gosund, BlitzWolf)

Any plug that pairs with the **Smart Life app** uses the Tuya protocol and works with this adapter.
```bash
pip install tinytuya
python3 -m tinytuya wizard
```

**Config:**
```json
{
  "plug_type": "tuya",
  "tuya": {
    "ip": "192.168.x.x",
    "device_id": "your_device_id",
    "local_key": "your_local_key",
    "version": 3.3,
    "dps_power_key": "19",
    "power_divisor": 10
  }
}
```

### Wipro-specific notes

Wipro plugs (10A and 16A) pair via the Smart Life app or the Wipro Next app.

**Problem: watts always reads 0.0W**
Try changing `dps_power_key` in config.json. Wipro plugs have been seen using keys `"19"`, `"111"`, or `"117"` depending on firmware. To find the correct key:
```bash
python3 -m tinytuya scan
```

**Problem: authentication fails**
Try changing `"version": 3.3` to `"version": 3.4` in config.json.

**Problem: energy readings are inconsistent**
Make sure firmware is updated via Wipro Next app → Device → Check for updates.

### Havells-specific notes

Havells Coral plugs use the Tuya protocol via Smart Life app. Default `dps_power_key: "19"` should work. If not, run `python3 -m tinytuya scan` to find the correct key.

---

## Plugs that will NOT work

| Plug | Reason |
|---|---|
| Tapo P100 | No energy monitoring |
| Tapo P105 | No energy monitoring |
| Kasa HS103 | No energy monitoring |
| Kasa KP105 | No energy monitoring |
| Any basic on/off plug | No energy monitoring |

---

## Adding support for a new plug

1. Create `plugs/myplug_adapter.py` inheriting from `BasePlugAdapter`
2. Implement `get_watts() -> float`
3. Register it in `plugs/base_adapter.py` factory method
4. Open a PR with test results

---

## Help us test

If you've tested a plug not marked ✅ above, please open a GitHub issue with plug model, firmware version, OS, and whether it worked out of the box or required config changes.
