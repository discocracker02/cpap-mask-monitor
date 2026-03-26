# Command Reference

All commands for managing, monitoring, troubleshooting and reporting on your CPAP Mask Monitor setup.

---

## Health checks

| Name | Command | What it does |
|---|---|---|
| Monitor running | `launchctl list \| grep cpap` | Confirms monitor service is active. Shows PID and status. |
| Caffeinate running | `pgrep caffeinate` | Confirms Mac sleep prevention is active. Should show a PID during sleep hours. |
| HTTP server running | `launchctl list \| grep httpserver` | Confirms the local HTTP alert server is active. |
| HTTP server status | `curl http://localhost:8765/status` | Returns `OK` (no alert) or `ALERT_PUSHOVER` / `ALERT_LOCAL`. |
| Mac uptime | `uptime` | Shows how long Mac has been on. Useful to verify no unexpected reboots. |
| Tapo reachable | `ping 192.168.x.x` | Checks if Tapo plug is reachable on the local network. Replace IP with yours. |

---

## Log inspection

| Name | Command | What it does |
|---|---|---|
| Live log | `tail -f ~/cpap_monitor.log` | Streams live log output. Shows power readings, mask on/off events, alerts. |
| Last 30 lines | `tail -30 ~/cpap_monitor.log` | Shows recent log entries. Good morning check. |
| All alerts | `grep "ALERT SENT" ~/cpap_monitor.log` | Lists every alert fired with timestamp. |
| Alert timestamps | `grep -B2 "ALERT SENT" ~/cpap_monitor.log \| grep "^\["` | Shows the timestamp of each alert event. |
| Monitor restarts | `grep "Monitor started" ~/cpap_monitor.log` | Shows how many times the monitor has restarted. Multiple restarts = crashes occurred. |
| Errors only | `grep "Error:" ~/cpap_monitor.log \| tail -20` | Lists recent errors — Tapo timeouts, auth failures etc. |
| Session starts | `grep "Mask ON" ~/cpap_monitor.log \| tail -10` | Shows when CPAP therapy sessions were detected. |
| Search by date | `grep "2026-03-25" ~/cpap_monitor.log` | Filters log to a specific date. Replace date as needed. |

---

## Service management

| Name | Command | What it does |
|---|---|---|
| Restart monitor | `launchctl unload ~/Library/LaunchAgents/com.cpap.monitor.plist && launchctl load ~/Library/LaunchAgents/com.cpap.monitor.plist` | Fully restarts the monitor service. Use after any config change. |
| Stop monitor | `launchctl unload ~/Library/LaunchAgents/com.cpap.monitor.plist` | Stops the monitor service. |
| Start monitor | `launchctl load ~/Library/LaunchAgents/com.cpap.monitor.plist` | Starts the monitor service. |
| Restart HTTP server | `launchctl unload ~/Library/LaunchAgents/com.cpap.httpserver.plist && launchctl load ~/Library/LaunchAgents/com.cpap.httpserver.plist` | Restarts the local HTTP alert server. |
| Run manually | `python3.11 cpap_monitor.py` | Runs monitor directly in terminal. Useful for testing and debugging. |

---

## Troubleshooting

| Name | Command | What it does |
|---|---|---|
| Kill caffeinate | `pkill caffeinate` | Kills all caffeinate instances. Useful if multiple are running. |
| Check Tapo IP | `grep "ip" config.json` | Shows the IP currently configured. |
| Clear alert flag | `curl http://localhost:8765/clear` | Clears the alert flag file. Use after a false alert. |
| Simulate alert | `echo "ALERT_LOCAL" > cpap_alert_flag.txt` | Simulates a local alert for testing. |
| Mac sleep log | `pmset -g log \| grep -E "Sleep\|Wake" \| tail -20` | Shows recent Mac sleep and wake events. Use to check if Mac slept during monitoring. |
| Check DHCP | `ping 192.168.x.x` | Verify Tapo plug is still at the reserved IP. If no response, IP may have changed — check Tapo app. |
| Reset state | `echo '{"session_started": false, "idle_since": null, "low_count": 0}' > cpap_state.json` | Resets monitor state. Use if monitor is stuck in a wrong state. |
| Check state | `cat cpap_state.json` | Shows current monitor state — session started, idle timer, low count. |

---

## Tapo plug setup

| Name | Command | What it does |
|---|---|---|
| Find plug IP | Open Tapo app → tap plug → Settings → Device Info → IP Address | Find the current local IP of your plug. |
| Reserve IP | Router settings → DHCP Reservation → add plug MAC → assign fixed IP | Prevents the plug IP from changing after a reboot. |
| Power cycle plug | Unplug from wall → wait 30s → plug back in | Fixes most Tapo auth / connectivity issues. |

---

## Notes

- All file paths assume the repo is cloned to your home directory. Adjust paths if installed elsewhere.
- Replace `192.168.x.x` with your actual Tapo plug IP throughout.
- Replace dates like `2026-03-25` with the actual date you want to query.
- The monitor only runs during sleep hours as configured in `config.json` (`sleep_start_hour` to `sleep_end_hour`).
