#!/bin/bash
set -e

# ---------------------------------------------------------------------------
# ELBE 15+ uses --qemu mode (no libvirt required)
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# ELBE workspace directories
# ---------------------------------------------------------------------------
mkdir -p /workspace/.elbe/initvm
chown -R developer:developer /workspace/.elbe

# ---------------------------------------------------------------------------
# ELBE UI – start the web interface in the background
# ---------------------------------------------------------------------------
if [ -f /workspace/tools/elbe-ui/main.py ]; then
    cd /workspace/tools/elbe-ui
    nohup python3 -m uvicorn main:app --host 0.0.0.0 --port 8080 --reload \
        > /var/log/elbe-ui.log 2>&1 &
    echo "ELBE UI started on http://0.0.0.0:8080"
    cd /workspace
elif [ -f /opt/elbe-ui/main.py ]; then
    cd /opt/elbe-ui
    nohup python3 -m uvicorn main:app --host 0.0.0.0 --port 8080 \
        > /var/log/elbe-ui.log 2>&1 &
    echo "ELBE UI started on http://0.0.0.0:8080 (from /opt/elbe-ui)"
    cd /workspace
fi

# Execute the command passed (or interactive bash)
exec "$@"
