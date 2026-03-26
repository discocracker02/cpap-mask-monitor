# CPAP Mask Monitor — Linux

Linux port of the CPAP Mask Monitor. Same functionality as the macOS version — real-time mask-off detection and Pushover alerts — adapted for Linux using systemd user services.

> **Status:** Community testing in progress. If you test this on Linux, please open an issue with your results — distro, version, and whether it worked.

---

## Requirements

### Hardware
- Tapo P110 smart plug (energy monitoring required)
- Any CPAP / APAP / BiPAP machine
- Linux machine that remains powered on during sleep hours (desktop, laptop, or Raspberry Pi)

### Software
- Ubuntu 22.04+ / Debian 12+ / Fedora 38+ / Arch Linux
- Python 3.10 or later
- Rust (installed automatically by the installer — required for the `tapo` library)
- Pushover account — [pushover.net](https://pushover.net) ($5 one-time per platform)
- systemd (standard on all supported distros)

### Network
- Linux machine and Tapo plug must be on the **same local WiFi network**
- Internet connection required for Pushover alerts

---

## Installation

### One-line install (recommended)

```bash
curl -sSL https://raw.githubusercontent.com/discocracker02/cpap-mask-monitor/main/linux/install.sh | bash
```

### Manual install

```bash
git clone https://github.com/discocracker02/cpap-mask-monitor.git
cd cpap-mask-monitor/linux
bash install.sh
```

The installer will:
- Detect your distro and install Python if missing
- Install Rust via rustup (required for the `tapo` library)
- Install `tapo` and `requests` Python libraries
- Copy files to `~/cpap-mask-monitor/`
- Open `config.json` in nano for you to fill in
- Register two systemd user services that start automatically at login
- Start both services immediately

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
    "sleep_end_hour": 9,
    "timezone_offset_hours": 5.5
  }
}
```

### Timezone offset

| Timezone | Offset |
|---|---|
| IST (India) | 5.5 |
| GMT (UK) | 0 |
| EST (US East) | -5 |
| CST (US Central) | -6 |
| PST (US West) | -8 |
| AEST (Australia East) | 10 |
| CET (Central Europe) | 1 |

### Calibrating watt_threshold

Run the monitor manually and watch the log:

```bash
python3 ~/cpap-mask-monitor/cpap_monitor.py
```

Note watts with mask on vs mask off. Set `watt_threshold` between the two values.

**Example (ResMed AirSense 11):**
- Mask on: 6–15W → Mask off: 2–3W → Threshold: 5W ✓

---

## Raspberry Pi

The Linux version works on Raspberry Pi 4B and later (64-bit ARM). Raspberry Pi Zero 2W should also work.

For always-on monitoring independent of a desktop/laptop, a Raspberry Pi is the recommended setup:
- Plug stays beside your CPAP machine
- Pi sits nearby on a USB power adapter
- Runs 24/7 with ~3W power draw
- Mac/Windows PC can sleep freely

> Note: Raspberry Pi Zero W (original, 32-bit) is **not supported** — Rust does not compile on 32-bit ARM.

---

## Sleep prevention

On macOS the monitor uses `caffeinate`. On Linux, sleep prevention is handled at the system level by the installer via:

```bash
loginctl enable-linger $USER
```

This ensures the systemd user services continue running even when the display is off or the user is not actively logged in. The services themselves keep the monitoring alive — no additional sleep inhibitor is needed for a headless setup.

If running on a desktop Linux with a display, you may want to also disable automatic suspend in your desktop environment's power settings.

---

## Known issues

### tapo fails to install — "Rust not found"
The installer runs rustup automatically. If it fails, install Rust manually:
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
pip3 install tapo
```

### pip install fails with "externally managed environment"
Ubuntu 23.04+ and Debian 12+ protect the system Python. The installer handles this automatically with `--break-system-packages`. If running manually:
```bash
pip3 install tapo requests --break-system-packages
```
Or use a virtual environment:
```bash
python3 -m venv ~/cpap-venv
source ~/cpap-venv/bin/activate
pip install tapo requests
```

### Services not starting after reboot
Make sure linger is enabled:
```bash
loginctl enable-linger $USER
systemctl --user enable cpap-monitor cpap-httpserver
```

### Tapo plug unreachable
- Verify IP in config.json matches plug's current IP (check Tapo app → Device Info)
- Make sure machine and plug are on same WiFi network
- Power cycle the plug and restart the monitor

---

## Limitations

| Limitation | Details |
|---|---|
| Same network required | Linux machine and Tapo plug must be on the same local WiFi network |
| Internet required for alerts | Pushover needs internet. If down, the flag file is written locally but no push notification is sent |
| No OSCAR integration | OSCAR AppleScript export is macOS only. Linux users will need to export CSV manually |
| Rust required | The `tapo` library requires Rust to install. The installer handles this automatically |

---

## Help us test

This Linux port is community-tested. If you try it, please open a GitHub issue with:
- Distro and version (e.g. Ubuntu 22.04)
- Architecture (x86_64, ARM64, ARM32)
- CPAP machine model
- Whether installation succeeded
- Whether monitoring worked correctly
- Any errors encountered

Your feedback directly shapes the next version.

---

See [COMMANDS_LINUX.md](COMMANDS_LINUX.md) for the full command reference.

See the main [README.md](../README.md) for full project documentation.
