# CPAP Mask Monitor

A lightweight macOS background service that detects when your CPAP mask is removed during sleep and alerts you immediately via Pushover.

---

## The Problem

Severe obstructive sleep apnea (OSA) requires consistent CPAP therapy throughout the night. However, many users — especially those with high pressure requirements — tend to unconsciously remove their mask during REM or deep sleep when discomfort peaks. When this happens, therapy stops completely, OSA events return, and sleep quality suffers — often without the user even remembering it happened.

ResMed's MyAir app shows a morning summary, but by then the damage is done. There was no way to get a real-time alert the moment the mask came off.

**This project solves that.**

---

## How It Works

A Tapo P110 smart plug sits between your CPAP machine and the wall socket. The monitor polls the plug every 2 minutes (configurable) and reads the current power consumption in watts:

- **Mask on, therapy running:** 6–15W (varies by pressure and machine model)
- **Mask off, machine idle/stopped:** 2–5W

When the monitor detects a sustained low watt reading (2 consecutive readings below threshold), it starts a timer. If the mask stays off for 10+ minutes, it fires a Pushover push notification to your phone — with priority 2 (emergency), which bypasses iOS Silent mode and Do Not Disturb.

```
CPAP Machine → Tapo P110 → Local WiFi → Mac (monitor script) → Pushover → Phone/Watch
```

---

## Requirements

### Hardware
- **CPAP machine** — tested with ResMed AirSense 10 and AirSense 11. Should work with any CPAP/APAP/BiPAP machine that uses a smart plug.
- **Tapo P110 smart plug** — the energy monitoring variant is required (P110, not P100). See [Supported Devices](#supported-devices) for other options.
- **Mac** — macOS 12 (Monterey) or later. Must remain powered on and connected to WiFi during sleep hours.

### Software
- Python 3.10 or later (3.11 recommended)
- [Pushover](https://pushover.net) account — one-time $5 purchase per platform (iOS or Android). Free 30-day trial available.
- Tapo account (free)

### Network
- Mac and Tapo plug must be on the **same local WiFi network**
- Internet connection required for Pushover alerts (see [Limitations](#limitations))

---

## Cost

| Item | Cost |
|---|---|
| This software | Free |
| Tapo P110 smart plug | ~₹1,500–2,000 / ~$18–25 |
| Pushover app (iOS or Android) | $5 one-time |
| Mac (you likely already have one) | — |

---

## Installation

### Option A — One-command install (recommended)

```bash
git clone https://github.com/discocracker02/cpap-mask-monitor.git
cd cpap-mask-monitor
bash install.sh
```

The installer will:
1. Check Python version
2. Install required libraries (`tapo`, `requests`)
3. Create `config.json` from the example and open it for you to fill in
4. Register a background service (launchd) that starts automatically at login
5. Start the monitor

### Option B — Manual setup

**1. Clone the repo:**
```bash
git clone https://github.com/discocracker02/cpap-mask-monitor.git
cd cpap-mask-monitor
```

**2. Install dependencies:**
```bash
pip3 install tapo requests
```

**3. Create config:**
```bash
cp config.example.json config.json
```
Edit `config.json` with your credentials (see [Configuration](#configuration)).

**4. Test it works:**
```bash
python3 cpap_monitor.py
```
You should see power readings appearing every 2 minutes.

**5. Run as background service:**
```bash
# Edit the plist to point to your Python path and repo directory
cp com.cpap.monitor.example.plist ~/Library/LaunchAgents/com.cpap.monitor.plist
# Edit the plist file with your actual paths
launchctl load ~/Library/LaunchAgents/com.cpap.monitor.plist
```

---

## Configuration

Copy `config.example.json` to `config.json` and fill in your details:

```json
{
  "tapo": {
    "email": "your_tapo_account_email@example.com",
    "password": "your_tapo_account_password",
    "ip": "192.168.x.x"
  },
  "pushover": {
    "user_key": "your_pushover_user_key",
    "app_token": "your_pushover_app_token"
  },
  "monitor": {
    "poll_seconds": 120,
    "idle_minutes": 10,
    "watt_threshold": 5,
    "confirm_count": 2,
    "sleep_start_hour": 22,
    "sleep_end_hour": 9
  }
}
```

### Config reference

| Key | Default | Description |
|---|---|---|
| `tapo.email` | — | Your TP-Link/Tapo account email |
| `tapo.password` | — | Your TP-Link/Tapo account password |
| `tapo.ip` | — | Local IP of your Tapo plug (find in Tapo app → Device Info) |
| `pushover.user_key` | — | Your Pushover user key |
| `pushover.app_token` | — | Your Pushover app token (create one at pushover.net) |
| `poll_seconds` | 120 | How often to poll the plug (seconds) |
| `idle_minutes` | 10 | How long mask must be off before alert fires (minutes) |
| `watt_threshold` | 5 | Watts below which mask is considered off |
| `confirm_count` | 2 | Number of consecutive low readings before timer starts |
| `sleep_start_hour` | 22 | Hour monitoring starts (24h, local time) |
| `sleep_end_hour` | 9 | Hour monitoring stops (24h, local time) |

### Calibrating watt_threshold for your machine

Every CPAP machine draws different power. Before setting `watt_threshold`:

1. Run `python3 cpap_monitor.py` while watching the log
2. Note the watts when mask is **on** and therapy is running
3. Note the watts when machine is **idle** (mask off, machine stopped)
4. Set `watt_threshold` to a value between the two

**Example (ResMed AirSense 11):**
- Mask on: 6–15W
- Mask off / idle: 2–3W
- Threshold: 5W ✓

### Finding your Tapo plug IP

Open the Tapo app → tap your plug → tap the settings icon → Device Info → IP Address.

**Tip:** Reserve a static IP for your plug in your router's DHCP settings so the IP never changes.

---

## Pushover Setup

1. Create a free account at [pushover.net](https://pushover.net)
2. Note your **User Key** on the dashboard
3. Create a new application → note the **API Token**
4. Download Pushover on your phone ($5 one-time)
5. In the Pushover app → Settings → enable **Critical Alerts** — this bypasses iOS Silent mode and Sleep Focus

---

## Supported Devices

### Tested
| Device | Status |
|---|---|
| TP-Link Tapo P110 | ✅ Tested |
| ResMed AirSense 10 AutoSet | ✅ Tested |
| ResMed AirSense 11 AutoSet | ✅ Tested |

### Should work (untested)
| Device | Notes |
|---|---|
| Tapo P110M | Same chip, energy monitoring |
| Tapo P115 | Energy monitoring variant |
| Tapo P105 | No energy monitoring — **will not work** |
| Tapo P100 | No energy monitoring — **will not work** |
| Any CPAP/APAP/BiPAP machine | Watt threshold calibration required |

> **Important:** Only Tapo plugs with energy monitoring (current power reading) are compatible. The P110 and P115 have this. The P100 and P105 do not.

---

## Known Issues & Troubleshooting

### Mac goes to sleep during the night
The monitor uses `caffeinate -s` to prevent system sleep during sleep hours. If your Mac still sleeps:
- Make sure the Mac is plugged into power (caffeinate only prevents sleep when charging)
- Check System Settings → Battery → disable "Put hard disks to sleep when possible"
- Closing the MacBook lid will force sleep regardless of caffeinate

### Tapo plug shows "Hash mismatch" error
This is a known issue with newer Tapo firmware (KLAP v2 authentication). Fixes to try:
1. Power cycle the plug (unplug and replug)
2. Restart the monitor service
3. Factory reset the plug and re-add it to the Tapo app
4. If you have multiple Tapo devices, remove them from the app one by one to isolate the conflict

### Alert fired but I didn't receive it on my phone
- Make sure Pushover **Critical Alerts** is enabled (Settings → Pushover → Critical Alerts → On)
- Check your Focus/Do Not Disturb settings — Critical Alerts bypass these, but must be specifically enabled in Pushover app settings
- Verify your Pushover User Key and App Token are correct in config.json

### False alerts (mask is on but alert fires)
Your `watt_threshold` may be too high for your machine. Reduce it:
1. Watch the log for 30 minutes during therapy
2. Note the minimum watts you see with mask on
3. Set threshold to 1W below that minimum

### No data / plug unreachable
- Verify the IP in config.json matches your plug's current IP (check Tapo app)
- Make sure Mac and plug are on the same WiFi network
- Try `ping 192.168.x.x` (your plug IP) from Terminal

---

## Limitations

| Limitation | Details |
|---|---|
| macOS only | Windows and Linux support planned for future versions |
| Same network required | Mac and Tapo plug must be on the same local WiFi network. Does not work when travelling unless you bring the plug and use a shared hotspot |
| Internet required for alerts | Pushover needs internet. If internet is down, the monitor logs the event locally but cannot send a push notification |
| Smart plug required | No smart plug = no monitoring. The plug is the only hardware addition needed |
| Mac must stay on | The Mac running the monitor must remain powered on and connected to WiFi during sleep hours |
| 2-minute detection delay | The monitor polls every 2 minutes by default. Minimum detection time is therefore 2 minutes after mask removal + 10 minute idle timer = up to 12 minutes before first alert |

---

## Roadmap

Community contributions welcome for:

- [ ] **Windows support** — port the launchd service to Windows Task Scheduler or a Windows service
- [ ] **Linux support** — systemd service file
- [ ] **Additional smart plugs** — Sonoff S31, Kasa EP25, Tuya-compatible plugs via local API
- [ ] **Additional alert providers** — Telegram bot, ntfy.sh, Home Assistant webhook
- [ ] **Web dashboard** — nightly summary, mask-off history, trend graphs
- [ ] **Android companion** — haptic alerts via local network when internet is unavailable
- [ ] **Multi-machine support** — for households with multiple CPAP users
- [ ] **Auto-calibration** — automatically determine watt threshold from first-night data

---

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you'd like to change.

If you've tested this with a CPAP machine or smart plug not listed above, please open an issue or PR to update the supported devices table.

---

## License

MIT — free to use, modify, and distribute. See [LICENSE](LICENSE) for details.

---

## Disclaimer

This tool is not a medical device. It is not intended to diagnose, treat, or monitor any medical condition. Always consult your physician regarding your CPAP therapy. The alert system is a convenience tool — do not rely solely on it for therapy compliance.

## Supported Smart Plugs
See [README_PLUGS.md](README_PLUGS.md) for the full list of supported plugs including Tapo, Kasa, Wipro, and Havells.
