# CPAP Mask Monitor — Windows

Windows port of the CPAP Mask Monitor. Same functionality as the macOS version — real-time mask-off detection and Pushover alerts — adapted for Windows using Task Scheduler and PowerShell.

> **Status:** Community testing in progress. If you test this on Windows, please open an issue with your results — machine model, Windows version, and whether it worked.

---

## Requirements

### Hardware
- Tapo P110 smart plug (energy monitoring required)
- Any CPAP / APAP / BiPAP machine
- Windows PC that remains powered on during sleep hours

### Software
- Windows 10 or Windows 11
- Python 3.10 or later — [download here](https://www.python.org/downloads/)
  - During installation: check **"Add Python to PATH"**
- Microsoft C++ Build Tools — [download here](https://visualstudio.microsoft.com/visual-cpp-build-tools/)
  - During installation: select **"Desktop development with C++"**
  - Required to install the `tapo` library. This is a ~1.5GB download.
- Pushover account — [pushover.net](https://pushover.net) ($5 one-time per platform)

### Network
- PC and Tapo plug must be on the **same local WiFi network**
- Internet connection required for Pushover alerts

---

## Installation

### One-command install (recommended)

1. Download and unzip the repo
2. Open **PowerShell as Administrator** (right-click → Run as Administrator)
3. Navigate to the repo folder:
   ```powershell
   cd C:\path\to\cpap-mask-monitor
   ```
4. Run the installer:
   ```powershell
   .\install.ps1
   ```

The installer will:
- Check Python and C++ Build Tools are present
- Install `tapo` and `requests` Python libraries
- Copy files to `%USERPROFILE%\cpap-mask-monitor\`
- Open `config.json` in Notepad for you to fill in
- Register two Task Scheduler tasks that start automatically at login
- Start both tasks immediately

### Manual install

1. Install Python 3.10+ with "Add to PATH" checked
2. Install Microsoft C++ Build Tools with "Desktop development with C++" selected
3. Install dependencies:
   ```powershell
   python -m pip install tapo requests
   ```
4. Copy `config.example.json` to `config.json` and fill in your details
5. Register tasks manually in Task Scheduler (see below) or run scripts directly:
   ```powershell
   python cpap_monitor.py
   python cpap_http_server.py
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
    "sleep_end_hour": 9,
    "timezone_offset_hours": 5.5
  }
}
```

### Timezone offset

Set `timezone_offset_hours` to match your local timezone:

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

Every CPAP machine draws different power. Run the monitor manually and watch the log:

```powershell
python "$env:USERPROFILE\cpap-mask-monitor\cpap_monitor.py"
```

Note watts with mask on vs mask off. Set threshold between the two values.

**Example (ResMed AirSense 11):**
- Mask on: 6–15W → Mask off: 2–3W → Threshold: 5W ✓

---

## How Windows sleep prevention works

On macOS, the monitor uses `caffeinate`. On Windows it uses `SetThreadExecutionState` via the Windows API — a standard Windows call that signals the system to stay awake while the monitor is running. It does not change any persistent power settings and has no effect when the monitor stops.

---

## Known issues

### tapo library fails to install
Make sure Microsoft C++ Build Tools are installed with "Desktop development with C++" selected. This is required to compile the Rust crypto component the `tapo` library depends on.

### Task Scheduler shows "Last Run Result: 0x1"
This means the script exited with an error. Check the log file:
```powershell
Get-Content "$env:USERPROFILE\cpap-mask-monitor\cpap_monitor.log" -Tail 30
```

### Tapo plug unreachable
- Verify the IP in config.json matches your plug's current IP (check Tapo app → Device Info)
- Make sure PC and plug are on the same WiFi network
- Power cycle the plug and restart the monitor

### PowerShell says "running scripts is disabled"
Run this once in PowerShell as Administrator:
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## Limitations

| Limitation | Details |
|---|---|
| PC must stay on | Windows power settings must allow the PC to stay awake. The monitor uses `SetThreadExecutionState` to signal this, but some aggressive power plans may override it. |
| Same network required | PC and Tapo plug must be on the same local WiFi network. |
| Internet required for alerts | Pushover needs internet. If internet is down, the flag file is written locally but no push notification is sent. |
| No OSCAR integration | OSCAR AppleScript export is macOS only. Windows OSCAR users will need to export CSV manually. |

---

## Help us test

This Windows port is community-tested. If you try it, please open a GitHub issue with:
- Windows version (10 or 11, 32-bit or 64-bit)
- CPAP machine model
- Whether installation succeeded
- Whether monitoring worked correctly
- Any errors encountered

Your feedback directly shapes the next version.

---

See [COMMANDS_WINDOWS.md](COMMANDS_WINDOWS.md) for the full PowerShell command reference.

See the main [README.md](../README.md) for full project documentation.
