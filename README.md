# Audio Hijack Watchdog

A macOS LaunchAgent that automatically manages Audio Hijack based on network connectivity, designed for remote broadcast stations.

## Overview

This watchdog system ensures Audio Hijack runs only when network connectivity is available, preventing crashes and resource waste during network outages. Perfect for remote broadcast setups where internet connectivity may be intermittent.

## Features

- **Network-aware operation**: Starts Audio Hijack when network is up, stops when network is down
- **Automatic recovery**: Relaunches Audio Hijack if it crashes (when network is available)
- **Logging**: Comprehensive logging to `/tmp/audiohijack-watchdog.out`
- **LaunchAgent integration**: Runs automatically at login and keeps running
- **Graceful shutdown**: Uses AppleScript to properly quit Audio Hijack

## Files

- `audiohijack-watchdog.sh` - Main watchdog script
- `com.caruso.audiohijackwatchdog.plist` - LaunchAgent configuration
- `run-btop.command` - System monitoring script (btop launcher)
- `com.caruso.btop.plist` - LaunchAgent for btop system monitor

## Installation

1. **Copy the script:**
   ```bash
   mkdir -p ~/scripts
   cp audiohijack-watchdog.sh ~/scripts/
   chmod +x ~/scripts/audiohijack-watchdog.sh
   ```

2. **Install the LaunchAgent:**
   ```bash
   cp com.caruso.audiohijackwatchdog.plist ~/Library/LaunchAgents/
   ```

3. **Install the system monitor (optional):**
   ```bash
   cp run-btop.command ~/scripts/
   cp com.caruso.btop.plist ~/Library/LaunchAgents/
   chmod +x ~/scripts/run-btop.command
   ```

4. **Load and start the services:**
   ```bash
   launchctl load ~/Library/LaunchAgents/com.caruso.audiohijackwatchdog.plist
   launchctl load ~/Library/LaunchAgents/com.caruso.btop.plist  # optional
   ```

## How It Works

The watchdog script runs continuously and:

1. **Checks network connectivity** every 60 seconds using `nc -z 8.8.8.8 53`
2. **When network is UP:**
   - Ensures Audio Hijack is running
   - Launches Audio Hijack if not found
3. **When network is DOWN:**
   - Gracefully quits Audio Hijack to prevent crashes
     (mostly works, but not always reliable) - Waits for network to return

## Monitoring

**Check if the watchdog is running:**
```bash
launchctl list | grep audiohijackwatchdog
ps aux | grep audiohijack-watchdog
```

**View logs:**
```bash
tail -f /tmp/audiohijack-watchdog.out
```

**Check Audio Hijack status:**
```bash
ps aux | grep "Audio Hijack"
```

## Configuration

Edit `audiohijack-watchdog.sh` to customize:

- `LOOP_INTERVAL=60` - Seconds between checks (default: 60)
- `CHECK_TIMEOUT=5` - Network check timeout (default: 5)
- `LOG_FILE` - Path to log file
- `ERR_FILE` - Path to error log

### ⚠️ Important Warning
**Do NOT enable warning-based restarts** in the watchdog script. If configured to restart Audio Hijack on warnings/errors, the watchdog will kill and restart the application every minute when modal dialogs appear, creating an endless restart loop. The current configuration only manages Audio Hijack based on network connectivity, which works reliably for most cases.

## Uninstallation

```bash
launchctl unload ~/Library/LaunchAgents/com.caruso.audiohijackwatchdog.plist
rm ~/Library/LaunchAgents/com.caruso.audiohijackwatchdog.plist
rm ~/scripts/audiohijack-watchdog.sh
```

## Use Case

This system was designed for remote broadcast stations where:
- Audio Hijack streams to remote servers
- Network connectivity is intermittent
- Unattended operation is required
- Audio Hijack crashes when servers are unreachable

The watchdog attempts to ensure Audio Hijack only runs when it can successfully stream, preventing resource waste and application instability.

## Logs Example

```
2025-09-04 07:37:39 – Watchdog started, waiting 60 s...
2025-09-04 07:38:39 – Network OK → launching Audio Hijack
2025-09-04 07:39:39 – Watchdog started, waiting 60 s...
2025-09-04 07:40:39 – Network down → killing Audio Hijack
```

## Compatibility

- **macOS:** 10.14+ (tested on macOS Sonoma/Ventura)
- **Audio Hijack:** Version 4.x
- **Dependencies:** Standard macOS utilities (`nc`, `pgrep`, `osascript`)

## Additional System Components

The complete remote broadcast monitoring system includes:

### Caffeinate (Keep-Alive)
- **System caffeinate:** PID 232 running as root with `-dimsu` flags
- **Purpose:** Prevents display sleep, idle sleep, disk sleep, and system sleep
- **Critical for:** 24/7 unattended operation in remote locations
- **Status:** Active system-wide sleep prevention

### btop System Monitor (Not Recommended)
- **Script:** `run-btop.command` - Launches btop system monitor
- **LaunchAgent:** `com.caruso.btop.plist` - Auto-starts btop at login
- **⚠️ Critical Issues:** 
  - **Cursor control:** btop takes control of the cursor, interfering with other applications
  - **Modal stacking:** Cannot dismiss Audio Hijack modal dialogs - they accumulate on screen
  - **Watchdog conflicts:** If watchdog is configured to restart on warnings, it will kill and restart Audio Hijack every minute when modals appear
- **Status:** Disabled in production due to these issues
- **Alternative:** Use system caffeinate for keep-alive; btop only for manual monitoring when user is present
- **Note:** Disabled by default now, as it was once critical for monitoring system resources on Mac Mini #2. We are on Mac Mini #3 now and BTOP is not needed.

## *OVERALL* Status

Currently running on production broadcast station "Chill-Deck-Mini" with:
- **Audio Hijack PID:** 77957 (running since 9:00PM, 134+ hours uptime)
- **Watchdog PID:** 586 (monitoring every 60 seconds)
- **Caffeinate PID:** 232 (system-wide sleep prevention)
- **Status:** Active monitoring, network-dependent operation, sleep prevention active

---

*Part of the ODA Broadcast System - Autonomous 24/7 HiFi broadcasting from remote locations.*
