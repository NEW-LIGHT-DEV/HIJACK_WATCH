#!/usr/bin/env bash
# --------------------------------------------------------------
# Audio Hijack Watchdog – full script (exactly as in the answer)
# --------------------------------------------------------------
AUDIO_HIJACK_PROC="Audio Hijack"
LOOP_INTERVAL=60          # seconds between status lines
CHECK_TIMEOUT=5           # seconds for the net‑check timeout
LOG_FILE="/tmp/audiohijack-watchdog.out"
ERR_FILE="/tmp/audiohijack-watchdog.err"

# --------------------------------------------------------------
# Do NOT enable "exit‑on‑error".  We deliberately use `set +e`.
# --------------------------------------------------------------
set +e

# Capture any command‑failure that would otherwise be silent
trap 'printf "\n--- ERROR %s (PID %s) ----\n" "$(date "+%Y-%m-%d %H:%M:%S")" "$$" >> "$ERR_FILE"' ERR

# A visible marker that the script has begun
printf "\n--- START %s (PID %s) ------------\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$$" >> "$LOG_FILE"

# --------------------------------------------------------------
# Helper functions (tiny, never abort)
# --------------------------------------------------------------
net_is_up() {
    # Use the absolute path to nc – launchd's PATH is minimal
    /usr/bin/nc -z -w "$CHECK_TIMEOUT" 8.8.8.8 53 >/dev/null 2>&1 && return 0 || return 1
}
launch_hijack() {
    /usr/bin/open -a "Audio Hijack"
    sleep 5                 # give the app a moment to appear
}
kill_hijack() {
    osascript -e 'tell application "Audio Hijack" to quit' >/dev/null 2>&1 || true
}

# --------------------------------------------------------------
# Main loop – prints a status line *every minute*
# --------------------------------------------------------------
while true; do
    if net_is_up; then
        # Network is up – make sure Audio Hijack is running
        if ! /usr/bin/pgrep -f "$AUDIO_HIJACK_PROC" >/dev/null; then
            printf "%s – Network OK → launching Audio Hijack\n" "$(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
            launch_hijack
            sleep 30          # give the app a few seconds before the next check
            continue
        fi
    else
        # Network is down – kill Audio Hijack if it's alive
        if /usr/bin/pgrep -f "$AUDIO_HIJACK_PROC" >/dev/null; then
            printf "%s – Network down → killing Audio Hijack\n" "$(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
            kill_hijack
        fi
    fi

    # This line is printed **every minute** while the script lives
    printf "%s – Watchdog started, waiting %s s...\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$LOOP_INTERVAL" >> "$LOG_FILE"
    sleep "$LOOP_INTERVAL"
done
