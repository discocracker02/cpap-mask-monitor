# Command Reference — Windows

All PowerShell commands for managing, monitoring, troubleshooting and reporting on your CPAP Mask Monitor setup on Windows.

> Run all commands in **PowerShell** (not Command Prompt).

---

## Health checks

| Name | Command | What it does |
|---|---|---|
| Monitor running | `Get-ScheduledTask -TaskName "CPAP Monitor"` | Shows monitor task status. State should be `Running`. |
| HTTP server running | `Get-ScheduledTask -TaskName "CPAP HTTP Server"` | Shows HTTP server task status. State should be `Running`. |
| HTTP server status | `Invoke-WebRequest http://localhost:8765/status \| Select -Expand Content` | Returns `OK`, `ALERT_PUSHOVER`, or `ALERT_LOCAL`. |
| Tapo reachable | `ping 192.168.x.x` | Checks if Tapo plug is reachable on the local network. Replace IP with yours. |
| System uptime | `(Get-Date) - (gcim Win32_OperatingSystem).LastBootUpTime` | Shows how long the PC has been running. |

---

## Log inspection

| Name | Command | What it does |
|---|---|---|
| Last 30 lines | `Get-Content "$env:USERPROFILE\cpap-mask-monitor\cpap_monitor.log" -Tail 30` | Shows recent log entries. Good morning check. |
| Live log | `Get-Content "$env:USERPROFILE\cpap-mask-monitor\cpap_monitor.log" -Tail 30 -Wait` | Streams live log output. |
| All alerts | `Select-String "ALERT SENT" "$env:USERPROFILE\cpap-mask-monitor\cpap_monitor.log"` | Lists every alert fired with timestamp. |
| Errors only | `Select-String "Error:" "$env:USERPROFILE\cpap-mask-monitor\cpap_monitor.log" \| Select -Last 20` | Lists recent errors. |
| Session starts | `Select-String "Mask ON" "$env:USERPROFILE\cpap-mask-monitor\cpap_monitor.log" \| Select -Last 10` | Shows when CPAP sessions were detected. |
| Monitor restarts | `Select-String "Monitor started" "$env:USERPROFILE\cpap-mask-monitor\cpap_monitor.log"` | Shows how many times the monitor restarted. |
| Search by date | `Select-String "2026-03-25" "$env:USERPROFILE\cpap-mask-monitor\cpap_monitor.log"` | Filters log to a specific date. Replace date as needed. |

---

## Service management

| Name | Command | What it does |
|---|---|---|
| Start monitor | `Start-ScheduledTask -TaskName "CPAP Monitor"` | Starts the monitor task. |
| Stop monitor | `Stop-ScheduledTask -TaskName "CPAP Monitor"` | Stops the monitor task. |
| Restart monitor | `Stop-ScheduledTask -TaskName "CPAP Monitor"; Start-Sleep 2; Start-ScheduledTask -TaskName "CPAP Monitor"` | Restarts the monitor. Use after any config change. |
| Start HTTP server | `Start-ScheduledTask -TaskName "CPAP HTTP Server"` | Starts the HTTP server task. |
| Stop HTTP server | `Stop-ScheduledTask -TaskName "CPAP HTTP Server"` | Stops the HTTP server task. |
| Restart HTTP server | `Stop-ScheduledTask -TaskName "CPAP HTTP Server"; Start-Sleep 2; Start-ScheduledTask -TaskName "CPAP HTTP Server"` | Restarts the HTTP server. |
| Run monitor manually | `python "$env:USERPROFILE\cpap-mask-monitor\cpap_monitor.py"` | Runs monitor directly in terminal. Useful for testing. |
| Open Task Scheduler | `taskschd.msc` | Opens the Task Scheduler GUI. Find both CPAP tasks here. |

---

## Troubleshooting

| Name | Command | What it does |
|---|---|---|
| Check Tapo IP | `Get-Content "$env:USERPROFILE\cpap-mask-monitor\config.json"` | Shows full config including the Tapo IP configured. |
| Clear alert flag | `Invoke-WebRequest http://localhost:8765/clear \| Select -Expand Content` | Clears the alert flag. Use after a false alert. |
| Simulate alert | `Set-Content "$env:USERPROFILE\cpap-mask-monitor\cpap_alert_flag.txt" "ALERT_LOCAL"` | Simulates a local alert for testing the iPhone Shortcut. |
| Check state file | `Get-Content "$env:USERPROFILE\cpap-mask-monitor\cpap_state.json"` | Shows current monitor state. |
| Reset state | `Set-Content "$env:USERPROFILE\cpap-mask-monitor\cpap_state.json" '{"session_started": false, "idle_since": null, "low_count": 0}'` | Resets monitor state. Use if monitor is stuck. |
| Check sleep settings | `powercfg /requests` | Shows what is preventing the system from sleeping. |
| Check Python install | `python --version` | Confirms Python is installed and in PATH. |
| Check tapo library | `python -c "import tapo; print('tapo OK')"` | Confirms the tapo library is installed correctly. |
| Reinstall dependencies | `python -m pip install tapo requests --upgrade` | Reinstalls/upgrades Python dependencies. |

---

## Tapo plug setup

| Name | Command | What it does |
|---|---|---|
| Find plug IP | Open Tapo app → tap plug → Settings → Device Info → IP Address | Find the current local IP of your plug. |
| Reserve IP | Router admin panel → DHCP Reservation → add plug MAC → assign fixed IP | Prevents the plug IP from changing after router reboot. |
| Power cycle plug | Unplug from wall → wait 30s → plug back in | Fixes most Tapo auth / connectivity issues. |

---

## Uninstall

| Name | Command | What it does |
|---|---|---|
| Remove tasks | `Unregister-ScheduledTask -TaskName "CPAP Monitor" -Confirm:$false; Unregister-ScheduledTask -TaskName "CPAP HTTP Server" -Confirm:$false` | Removes both scheduled tasks. |
| Remove files | `Remove-Item "$env:USERPROFILE\cpap-mask-monitor" -Recurse -Force` | Deletes all installed files. Run after removing tasks. |

---

## Notes

- All commands assume default install path `%USERPROFILE%\cpap-mask-monitor`. Adjust if you installed elsewhere.
- Replace `192.168.x.x` with your actual Tapo plug IP.
- Replace dates like `2026-03-25` with the actual date you want to query.
- The monitor only runs actively during sleep hours as configured in `config.json`.
- `timezone_offset_hours` in config.json must match your local timezone. Examples: IST = 5.5, GMT = 0, EST = -5, PST = -8, AEST = 10.
