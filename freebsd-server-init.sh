#!/bin/sh
#
# FreeBSD Server Initialization Master Script
# Target: FreeBSD 14.x / 15.x
#
# Workflow:
# 1. Download all four Gist scripts
# 2. Install default dependencies
# 3. Install and configure bhyve
# 4. Install Ookla Speedtest and iperf3
# 5. Request approval before running the stress test
#

set -eu

BASE_DIR="/root/server-init"
SCRIPT_DIR="${BASE_DIR}/scripts"
LOG_DIR="/var/log/server-init"
STAMP="$(date '+%Y%m%d-%H%M%S')"
LOG_FILE="${LOG_DIR}/init-${STAMP}.log"

DEFAULT_URL="https://gist.githubusercontent.com/Christo-heal/264516bae501b1ad0fdca94265255c7b/raw/"
BHYVE_URL="https://gist.githubusercontent.com/Christo-heal/89bfc386eabc34e87970882df262684f/raw/"
SPEEDTEST_URL="https://gist.githubusercontent.com/Christo-heal/2226c22a323c8c12d6d9572772aae42c/raw/"
STRESS_URL="https://gist.githubusercontent.com/Christo-heal/32aad302d07bc46b6af049451978e994/raw/"

DEFAULT_SCRIPT="${SCRIPT_DIR}/default-dependency.sh"
BHYVE_SCRIPT="${SCRIPT_DIR}/install-vm-bhyve.sh"
SPEEDTEST_SCRIPT="${SCRIPT_DIR}/install-speedtest.sh"
STRESS_SCRIPT="${SCRIPT_DIR}/stress-test.sh"

log() {
    printf '\nℹ️  [INFO] %s\n' "$*"
}

fail() {
    printf '\n❌ [ERROR] %s\n' "$*" >&2
    exit 1
}

pause() {
    printf '\n'
    printf 'Press Enter to continue... '
    read -r _
}

run_script() {
    description="$1"
    script_path="$2"

    printf '\n'
    printf '%s\n' "=================================================="
    log "$description"
    printf '%s\n' "=================================================="

    if ! /usr/local/bin/bash "$script_path"; then
        fail "$description failed. Remaining steps have been stopped."
    fi

    log "$description completed successfully."
}

# --------------------------------------------------
# Preflight checks
# --------------------------------------------------

if [ "$(id -u)" -ne 0 ]; then
    fail "Root privileges are required. Run this script as root."
fi

if [ "$(uname -s)" != "FreeBSD" ]; then
    fail "This script is intended for FreeBSD only."
fi

if ! command -v fetch >/dev/null 2>&1; then
    fail "The fetch utility is unavailable."
fi

mkdir -p "$SCRIPT_DIR" "$LOG_DIR"
chmod 700 "$BASE_DIR" "$SCRIPT_DIR" "$LOG_DIR"

# Log output to both the console and the main log.
exec > >(tee -a "$LOG_FILE") 2>&1

printf '%s\n' "=================================================="
printf '%s\n' "🚀 FreeBSD Server Initialization"
printf '🖥️  Host: %s\n' "$(hostname)"
printf '📅 Started: %s\n' "$(date)"
printf '📝 Log: %s\n' "$LOG_FILE"
printf '📂 Script directory: %s\n' "$SCRIPT_DIR"
printf '%s\n' "=================================================="

# --------------------------------------------------
# Step 1: Download all Gist scripts
# --------------------------------------------------

download_script() {
    name="$1"
    url="$2"
    destination="$3"
    temporary="${destination}.download"

    log "Downloading ${name}..."

    rm -f "$temporary"

    if ! fetch -q -o "$temporary" "$url"; then
        rm -f "$temporary"
        fail "Failed to download ${name}."
    fi

    if [ ! -s "$temporary" ]; then
        rm -f "$temporary"
        fail "${name} is empty."
    fi

    if ! grep -qE '^#!|^set[[:space:]]|^#[[:space:]]' "$temporary"; then
        rm -f "$temporary"
        fail "${name} does not appear to be a valid shell script."
    fi

    mv "$temporary" "$destination"
    chmod 600 "$destination"

    log "Downloaded successfully: ${name}"
}

printf '\n%s\n' "📥 === Step 1: Download All Scripts ==="

download_script "Default Dependency" "$DEFAULT_URL" "$DEFAULT_SCRIPT"
download_script "Bhyve Installer" "$BHYVE_URL" "$BHYVE_SCRIPT"
download_script "Speedtest Installer" "$SPEEDTEST_URL" "$SPEEDTEST_SCRIPT"
download_script "Stress Test" "$STRESS_URL" "$STRESS_SCRIPT"

log "All four scripts have been downloaded."

printf '\n%s\n' "📋 Downloaded files:"
printf '  - %s\n' "$DEFAULT_SCRIPT"
printf '  - %s\n' "$BHYVE_SCRIPT"
printf '  - %s\n' "$SPEEDTEST_SCRIPT"
printf '  - %s\n' "$STRESS_SCRIPT"

# --------------------------------------------------
# Bootstrap Bash if needed
# --------------------------------------------------

if [ ! -x /usr/local/bin/bash ]; then
    log "Bash is required to execute the downloaded scripts."
    log "Installing Bash..."

    if ! pkg install -y bash; then
        fail "Could not install Bash."
    fi
fi

# --------------------------------------------------
# Step 2: Default dependencies
# --------------------------------------------------

printf '\n%s\n' "📦 === Step 2: Default Dependency Installation ==="

run_script "Default Dependency Installation" "$DEFAULT_SCRIPT"

# --------------------------------------------------
# Step 3: Bhyve
# --------------------------------------------------

printf '\n%s\n' "🖥️ === Step 3: Bhyve Installation ==="

run_script "Bhyve Installation and Configuration" "$BHYVE_SCRIPT"

# --------------------------------------------------
# Step 4: Speedtest and iperf3
# --------------------------------------------------

printf '\n%s\n' "🌐 === Step 4: Network Testing Tools ==="

run_script "Ookla Speedtest and iperf3 Installation" "$SPEEDTEST_SCRIPT"

# --------------------------------------------------
# Step 5: Stress test approval
# --------------------------------------------------

printf '\n%s\n' "🔥 === Step 5: Stress Test Approval ==="

printf '\n'
printf '%s\n' "The installation stages have completed successfully."
printf '%s\n' "The CPU + RAM stress test has NOT started yet."
printf '\n'
printf '%s\n' "Stress test configuration:"
printf '%s\n' "  - Duration: 2 hours (default)"
printf '%s\n' "  - CPU workers: Detected automatically by the script"
printf '%s\n' "  - RAM allocation: 4 workers x 6 GiB (default)"
printf '\n'
printf '%s\n' "⚠️ Review the RAM allocation before running the test."
printf '\n'
printf '%s\n' "  [1] Continue and start the stress test"
printf '%s\n' "  [2] Edit the stress test script first"
printf '\n'

while :; do
    printf 'Select an option [1/2]: '
    read -r choice

    case "$choice" in
        1)
            log "Stress test approved."
            break
            ;;
        2)
            if ! command -v vi >/dev/null 2>&1; then
                fail "The vi editor is unavailable."
            fi

            log "Opening the stress test script for editing..."
            vi "$STRESS_SCRIPT"

            printf '\n'
            printf '%s\n' "📝 Current stress test configuration:"
            grep -nE '^(DURATION|CPU_WORKERS|VM_WORKERS|VM_BYTES)=' "$STRESS_SCRIPT" || true

            printf '\n'
            printf '%s\n' "Review your changes before continuing."
            printf '%s\n' "  [1] Save changes and run the stress test"
            printf '%s\n' "  [2] Reopen the editor"
            printf '%s\n' "  [3] Cancel the stress test"

            while :; do
                printf 'Select an option [1/2/3]: '
                read -r edit_choice

                case "$edit_choice" in
                    1)
                        break
                        ;;
                    2)
                        vi "$STRESS_SCRIPT"
                        grep -nE '^(DURATION|CPU_WORKERS|VM_WORKERS|VM_BYTES)=' "$STRESS_SCRIPT" || true
                        ;;
                    3)
                        log "Stress test cancelled by the administrator."
                        log "All previous installation stages remain completed."
                        exit 0
                        ;;
                    *)
                        printf '%s\n' "⚠️ Invalid selection. Enter 1, 2, or 3."
                        ;;
                esac
            done

            break
            ;;
        *)
            printf '%s\n' "⚠️ Invalid selection. Enter 1 or 2."
            ;;
    esac
done

# --------------------------------------------------
# Final confirmation and stress test
# --------------------------------------------------

printf '\n'
printf '%s\n' "⚠️ FINAL WARNING"
printf '%s\n' "The stress test will heavily load the CPU and allocate RAM."
printf '%s\n' "Make sure the server has sufficient available memory."
printf '\n'
printf 'Type YES to start the stress test: '
read -r confirmation

if [ "$confirmation" != "YES" ]; then
    log "Stress test cancelled. No stress test was started."
    exit 0
fi

run_script "CPU + RAM Stress Test" "$STRESS_SCRIPT"

# --------------------------------------------------
# Completion
# --------------------------------------------------

printf '\n%s\n' "=================================================="
printf '%s\n' "🎉 FreeBSD Server Initialization Completed!"
printf '🖥️  Host: %s\n' "$(hostname)"
printf '📅 Finished: %s\n' "$(date)"
printf '📝 Main log: %s\n' "$LOG_FILE"
printf '📂 Scripts: %s\n' "$SCRIPT_DIR"
printf '%s\n' "=================================================="

exit 0