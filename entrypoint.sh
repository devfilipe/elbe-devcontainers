#!/bin/bash
set -e

# ---------------------------------------------------------------------------
# ELBE 15+ uses --qemu mode (no libvirt required)
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# ELBE workspace directories
# ---------------------------------------------------------------------------
VMS_DIR="/workspace/.elbe/vms"
DEFAULT_VM_DIR="$VMS_DIR/initvm"
DEFAULT_SOAP_PORT=7587
ELBE_LOG_DIR="/workspace/.elbe/logs"

# Named volumes are mounted as root — fix ownership so developer can write
mkdir -p "$VMS_DIR" "$ELBE_LOG_DIR"
chown -R developer:developer "$VMS_DIR" "$ELBE_LOG_DIR"

# ---------------------------------------------------------------------------
# Default VM config file (tracks soap_port per VM)
# ---------------------------------------------------------------------------
if [ ! -f "$DEFAULT_VM_DIR/.vm_config.json" ]; then
    mkdir -p "$DEFAULT_VM_DIR"
    echo "{\"soap_port\": $DEFAULT_SOAP_PORT}" > "$DEFAULT_VM_DIR/.vm_config.json"
    chown -R developer:developer "$DEFAULT_VM_DIR"
fi

# ---------------------------------------------------------------------------
# ELBE UI – start the web interface in the background
# ---------------------------------------------------------------------------
if [ -f /workspace/tools/elbe-ui/main.py ]; then
    cd /workspace/tools/elbe-ui
    nohup python3 -m uvicorn main:app --host 0.0.0.0 --port 8080 --reload \
        >> "$ELBE_LOG_DIR/elbe-ui.log" 2>&1 &
    echo "ELBE UI started on http://0.0.0.0:8080"
    cd /workspace
elif [ -f /opt/elbe-ui/main.py ]; then
    cd /opt/elbe-ui
    nohup python3 -m uvicorn main:app --host 0.0.0.0 --port 8080 \
        >> "$ELBE_LOG_DIR/elbe-ui.log" 2>&1 &
    echo "ELBE UI started on http://0.0.0.0:8080 (from /opt/elbe-ui)"
    cd /workspace
fi

# ---------------------------------------------------------------------------
# Default initvm: create (if new or incomplete) then start; or just start
#
# initvm.img is the final artifact of 'elbe initvm create'.
# If it is absent the VM was never fully created (or was interrupted).
# ---------------------------------------------------------------------------
if [ ! -f "$DEFAULT_VM_DIR/initvm.img" ]; then
    echo "Default initvm not ready — creating then starting in background (takes 15-30 min)..."
    echo "  Log: $ELBE_LOG_DIR/initvm.log"
    su -s /bin/bash developer -c "
        elbe initvm create --qemu --directory $DEFAULT_VM_DIR \
            --port $DEFAULT_SOAP_PORT --skip-build-sources \
            > $ELBE_LOG_DIR/initvm.log 2>&1 &&
        elbe initvm start --qemu --directory $DEFAULT_VM_DIR \
            --port $DEFAULT_SOAP_PORT \
            >> $ELBE_LOG_DIR/initvm.log 2>&1
    " &
else
    echo "Starting default initvm at $DEFAULT_VM_DIR..."
    echo "  Log: $ELBE_LOG_DIR/initvm.log"
    su -s /bin/bash developer -c "
        elbe initvm start --qemu --directory $DEFAULT_VM_DIR \
            --port $DEFAULT_SOAP_PORT \
            > $ELBE_LOG_DIR/initvm.log 2>&1
    " &
fi

# Execute the command passed (or interactive bash)
exec "$@"
