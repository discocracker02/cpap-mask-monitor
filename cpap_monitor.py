#!/usr/bin/env python3
"""
CPAP Mask Monitor
-----------------
Detects when a CPAP mask is removed during sleep and sends an alert via Pushover.
Works by monitoring power consumption of the CPAP machine via a Tapo P110 smart plug.

GitHub: https://github.com/discocracker02/cpap-mask-monitor
License: MIT
"""

import asyncio
import json
import os
import time
from datetime import datetime, timezone, timedelta
from pathlib import Path

import requests
from tapo import ApiClient

# ── Load config ───────────────────────────────────────────────────────────────

BASE_DIR    = Path(__file__).parent
CONFIG_PATH = BASE_DIR / "config.json"

if not CONFIG_PATH.exists():
    print("ERROR: config.json not found.")
    print("Copy config.example.json to config.json and fill in your details.")
    exit(1)

with open(CONFIG_PATH) as f:
    config = json.load(f)

TAPO_EMAIL      = config["tapo"]["email"]
TAPO_PASSWORD   = config["tapo"]["password"]
TAPO_IP         = config["tapo"]["ip"]

PUSHOVER_USER   = config["pushover"]["user_key"]
PUSHOVER_TOKEN  = config["pushover"]["app_token"]

POLL_SECS       = config["monitor"].get("poll_seconds", 120)
IDLE_MINS       = config["monitor"].get("idle_minutes", 10)
WATT_THRESHOLD  = config["monitor"].get("watt_threshold", 5)
CONFIRM_COUNT   = config["monitor"].get("confirm_count", 2)
SLEEP_START     = config["monitor"].get("sleep_start_hour", 22)
SLEEP_END       = config["monitor"].get("sleep_end_hour", 9)

IST             = timezone(timedelta(hours=5, minutes=30))
STATE_FILE      = BASE_DIR / "cpap_state.json"
FLAG_FILE       = BASE_DIR / "cpap_alert_flag.txt"

# ── Helpers ───────────────────────────────────────────────────────────────────

def is_sleep_time():
    hour = datetime.now(IST).hour
    return hour >= SLEEP_START or hour < SLEEP_END

def set_mac_awake(prevent):
    """Keep Mac awake during sleep hours using caffeinate."""
    if prevent:
        os.system("pkill caffeinate 2>/dev/null; caffeinate -s &")
    else:
        os.system("pkill caffeinate")

def load_state():
    if STATE_FILE.exists():
        with open(STATE_FILE) as f:
            return json.load(f)
    return {"session_started": False, "idle_since": None, "low_count": 0}

def save_state(state):
    with open(STATE_FILE, "w") as f:
        json.dump(state, f)

def send_alert(message):
    """Send alert via Pushover. Falls back to local flag if no internet."""
    try:
        r = requests.post("https://api.pushover.net/1/messages.json", data={
            "token":   PUSHOVER_TOKEN,
            "user":    PUSHOVER_USER,
            "title":   "CPAP Alert",
            "message": message,
            "priority": 2,
            "retry":   60,
            "expire":  3600,
            "sound":   "siren"
        }, timeout=5)
        if r.status_code == 200:
            FLAG_FILE.write_text("ALERT_PUSHOVER")
            print(f"[{datetime.now(IST).strftime('%Y-%m-%d %H:%M')}] [ALERT SENT via Pushover] {message}")
        else:
            raise Exception(f"Pushover returned {r.status_code}")
    except Exception as e:
        FLAG_FILE.write_text("ALERT_LOCAL")
        print(f"[{datetime.now(IST).strftime('%Y-%m-%d %H:%M')}] [ALERT SENT via local flag] {message} (Pushover failed: {e})")

# ── Main loop ─────────────────────────────────────────────────────────────────

async def main():
    print("CPAP Monitor started")
    client = ApiClient(TAPO_EMAIL, TAPO_PASSWORD)

    while True:
        try:
            now_ist = datetime.now(IST)

            if not is_sleep_time():
                print(f"[{now_ist.strftime('%Y-%m-%d %H:%M')}] Not sleep time, standby...")
                save_state({"session_started": False, "idle_since": None, "low_count": 0})
                set_mac_awake(False)
                await asyncio.sleep(POLL_SECS)
                continue

            set_mac_awake(True)

            device = await client.p110(TAPO_IP)
            info   = await device.get_energy_usage()
            watts  = info.current_power / 1000
            state  = load_state()
            now_ts = time.time()

            print(f"[{now_ist.strftime('%Y-%m-%d %H:%M')}] Power: {watts:.1f}W | session_started: {state['session_started']}")

            if watts > WATT_THRESHOLD:
                # Mask is on - reset idle tracking
                state["session_started"] = True
                state["idle_since"]      = None
                state["low_count"]       = 0
                print("Mask ON")

            elif state["session_started"]:
                # Session active but low watts - potential mask off
                state["low_count"] = state.get("low_count", 0) + 1

                if state["low_count"] < CONFIRM_COUNT:
                    print(f"Low reading #{state['low_count']} - confirming...")

                elif state["idle_since"] is None:
                    state["idle_since"] = now_ts
                    print("Mask OFF confirmed - timer started")

                else:
                    idle_mins = (now_ts - state["idle_since"]) / 60
                    print(f"Mask off for {idle_mins:.1f} mins")

                    if idle_mins >= IDLE_MINS:
                        send_alert(f"CPAP mask off for {int(idle_mins)} mins! Put it back on.")
                        # Reset timer so alert fires again if mask stays off
                        state["idle_since"] = now_ts

            else:
                print("Waiting for session to start...")

            save_state(state)

        except Exception as e:
            print(f"Error: {e}")

        await asyncio.sleep(POLL_SECS)

if __name__ == "__main__":
    asyncio.run(main())
