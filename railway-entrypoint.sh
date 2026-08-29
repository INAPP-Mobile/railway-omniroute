#!/bin/sh
set -e

# ── Adaptive V8 heap sizing ────────────────────────────────────────────────
# Explicit OMNIROUTE_MEMORY_MB (image default is intentionally blanked in the
# Dockerfile) always wins. Otherwise derive heap from the container's cgroup
# memory limit at 60%, floored at 614MB — the verified boot + dashboard-render
# floor under Railway's 1GB Trial service cap (upstream's baked 1024 heap
# OOM-kills there; 512MB plans cannot fit this app at any heap).
if [ -z "$OMNIROUTE_MEMORY_MB" ]; then
  LIMIT_BYTES=""
  if [ -r /sys/fs/cgroup/memory.max ]; then
    LIMIT_BYTES=$(cat /sys/fs/cgroup/memory.max 2>/dev/null || echo "")
  fi
  # cgroup v1 fallback; treat "max" (unlimited) as unset
  if [ -z "$LIMIT_BYTES" ] || [ "$LIMIT_BYTES" = "max" ]; then
    if [ -r /sys/fs/cgroup/memory/memory.limit_in_bytes ]; then
      LIMIT_BYTES=$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes 2>/dev/null || echo "")
    fi
  fi
  HEAP_MB=""
  case "$LIMIT_BYTES" in
    ""|max) ;;
    *)
      if [ "$LIMIT_BYTES" -gt 0 ] 2>/dev/null && [ "$LIMIT_BYTES" -lt 9007199254740992 ] 2>/dev/null; then
        HEAP_MB=$((LIMIT_BYTES / 1048576 * 60 / 100))
      fi
      ;;
  esac
  if [ -z "$HEAP_MB" ] || [ "$HEAP_MB" -lt 614 ] 2>/dev/null; then
    HEAP_MB=614
  fi
  export OMNIROUTE_MEMORY_MB="$HEAP_MB"
fi

# ── App start ──────────────────────────────────────────────────────────────
# Runs as root (USER root): Railway mounts volumes root-owned, and uid 1000
# cannot write them -> fatal EACCES on the SQLite dir. Root matches the
# official upstream template behavior on Railway.
mkdir -p "${DATA_DIR:-/app/data}" 2>/dev/null || true
exec /tmp/check-permissions.sh "$@"