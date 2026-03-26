# Command Reference — Linux

All commands for managing, monitoring, troubleshooting and reporting on your CPAP Mask Monitor setup on Linux.

> Tested on Ubuntu 22.04 and Debian 12. Should work on Fedora and Arch.

---

## Health checks

| Name | Command | What it does |
|---|---|---|
| Monitor running | `systemctl --user status cpap-monitor` | Shows monitor service status, uptime and recent log lines. |
| HTTP server running | `systemctl --user status cpap-httpserver` | Shows HTTP server status. |
| HTTP server status | `curl http://localhost:8765/status` | Returns `OK`, `ALERT_PUSHOVER`, or `ALERT_LOCAL`. |
| Tapo reachable | `ping 192.168.x.x` | Checks if Tapo plug is reachable on the local network. Replace IP with yours. |
| System uptime | `uptime` | Shows how long the system has been running. |
| All services | `systemctl --user list-units --type=service \| grep cpap` | Lists all CPAP-related services and their states. |

---

## Log inspection

| Name | Command | What it does |
|---|---|---|
| Live log | `tail -f ~/cpap-mask-monitor/cpap_monitor.log` | Streams live log output. |
| Last 30 lines | `tail -30 ~/cpap-mask-monitor/cpap_monitor.log` | Shows recent log entries. Good morning check. |
| All alerts | `grep "ALERT SENT" ~/cpap-mask-monitor/cpap_monitor.log` | Lists every alert fired with timestamp. |
| Alert timestamps | `grep -B2 "ALERT SENT" ~/cpap-mask-monitor/cpap_monitor.log \| grep "^\["` | Shows timestamp of each alert. |
| Monitor restarts | `grep "Monitor started" ~/cpap-mask-monitor/cpap_monitor.log` | Shows how many times the monitor restarted. |
| Errors only | `grep "Error:" ~/cpap-mask-monitor/cpap_monitor.log \| tail -20` | Lists recent errors. |
| Session starts | `grep "Mask ON" ~/cpap-mask-monitor/cpap_monitor.log \| tail -10` | Shows when CPAP sessions were detected. |
| Search by date | `grep "2026-03-25" ~/cpap-mask-monitor/cpap_monitor.log` | Filters log to a specific date. |
| systemd journal | `journalctl --user -u cpap-monitor -n 50` | Shows recent logs via systemd journal. |

---

## Service management

| Name | Command | What it does |
|---|---|---|
| Start monitor | `systemctl --user start cpap-monitor` | Starts the monitor service. |
| Stop monitor | `systemctl --user stop cpap-monitor` | Stops the monitor service. |
| Restart monitor | `systemctl --user restart cpap-monitor` | Restarts the monitor. Use after any config change. |
| Start HTTP server | `systemctl --user start cpap-httpserver` | Starts the HTTP server. |
| Stop HTTP server | `systemctl --user stop cpap-httpserver` | Stops the HTTP server. |
| Restart HTTP server | `systemctl --user restart cpap-httpserver` | Restarts the HTTP server. |
| Enable on boot | `systemctl --user enable cpap-monitor cpap-httpserver` | Ensures services start automatically on login. |
| Disable on boot | `systemctl --user disable cpap-monitor cpap-httpserver` | Prevents services from starting automatically. |
| Run manually | `python3 ~/cpap-mask-monitor/cpap_monitor.py` | Runs monitor directly in terminal. Useful for testing. |
| Reload systemd | `systemctl --user daemon-reload` | Reloads systemd after editing service files. |

---

## Troubleshooting

| Name | Command | What it does |
|---|---|---|
| Check config | `cat ~/cpap-mask-monitor/config.json` | Shows full config including Tapo IP and credentials. |
| Check state | `cat ~/cpap-mask-monitor/cpap_state.json` | Shows current monitor state. |
| Reset state | `echo '{"session_started": false, "idle_since": null, "low_count": 0}' > ~/cpap-mask-monitor/cpap_state.json` | Resets monitor state if stuck. |
| Clear alert flag | `curl http://localhost:8765/clear` | Clears the alert flag. Use after a false alert. |
| Simulate alert | `echo "ALERT_LOCAL" > ~/cpap-mask-monitor/cpap_alert_flag.txt` | Simulates a local alert for testing. |
| Check Python | `python3 --version` | Confirms Python is installed. |
| Check tapo library | `python3 -c "import tapo; print('tapo OK')"` | Confirms tapo library is installed. |
| Check Rust | `rustc --version` | Confirms Rust is installed (required for tapo). |
| Reinstall dependencies | `pip3 install tapo requests --upgrade --break-system-packages` | Reinstalls Python dependencies. |
| View service file | `cat ~/.config/systemd/user/cpap-monitor.service` | Shows the systemd service definition. |

---

## Tapo plug setup

| Name | Command | What it does |
|---|---|---|
| Find plug IP | Open Tapo app → tap plug → Settings → Device Info → IP Address | Find the current local IP of your plug. |
| Reserve IP | Router admin panel → DHCP Reservation → add plug MAC → assign fixed IP | Prevents plug IP from changing after router reboot. |
| Power cycle plug | Unplug from wall → wait 30s → plug back in | Fixes most Tapo auth / connectivity issues. |

---

## Uninstall

| Name | Command | What it does |
|---|---|---|
| Stop and disable | `systemctl --user stop cpap-monitor cpap-httpserver && systemctl --user disable cpap-monitor cpap-httpserver` | Stops and disables both services. |
| Remove service files | `rm ~/.config/systemd/user/cpap-monitor.service ~/.config/systemd/user/cpap-httpserver.service && systemctl --user daemon-reload` | Removes systemd service files. |
| Remove install dir | `rm -rf ~/cpap-mask-monitor` | Deletes all installed files. Run after removing services. |

---

## Notes

- All paths assume default install to `~/cpap-mask-monitor`. Adjust if installed elsewhere.
- Replace `192.168.x.x` with your actual Tapo plug IP.
- `timezone_offset_hours` in config.json must match your timezone. Examples: IST = 5.5, GMT = 0, EST = -5, PST = -8, AEST = 10.
- Services run as user services (not root) — no sudo required after install.
- `loginctl enable-linger` is set during install so services run even when no user is logged in.
