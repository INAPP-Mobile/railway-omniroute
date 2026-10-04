#!/bin/sh
set -e

# ── Adaptive V8 heap sizing ────────────────────────────────────────────────
# Explicit OMNIROUTE_MEMORY_MB (both image defaults are intentionally blanked
# in the Dockerfile) always wins. Otherwise derive heap from the container's
# cgroup memory limit at 60%, floored at 614MB — the verified boot +
# dashboard-render floor under a 1GB service cap.
#
# The floor is capped at the container's own limit. A 0.5GB service gets a
# 307MB heap rather than a 614MB one: V8 sizing its heap ABOVE the cgroup limit
# lets RSS grow past the limit before the collector runs, which is exactly the
# cgroup OOM-kill -> restart -> healthcheck FAIL loop the template is fighting.
# Sizing under the limit keeps the JS heap inside the container's budget and
# lets V8 GC reclaim before the kernel kills the process.
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
  LIMIT_MB=""
  case "$LIMIT_BYTES" in
    ""|max) ;;
    *)
      if [ "$LIMIT_BYTES" -gt 0 ] 2>/dev/null && [ "$LIMIT_BYTES" -lt 9007199254740992 ] 2>/dev/null; then
        LIMIT_MB=$((LIMIT_BYTES / 1048576))
      fi
      ;;
  esac
  HEAP_MB=""
  if [ -n "$LIMIT_MB" ]; then
    HEAP_MB=$((LIMIT_MB * 60 / 100))
    if [ "$HEAP_MB" -lt 614 ] 2>/dev/null; then
      # Only apply the 614MB floor when the container can actually hold it.
      HEAP_MB=614
      if [ "$HEAP_MB" -gt "$LIMIT_MB" ] 2>/dev/null; then
        HEAP_MB=$LIMIT_MB
      fi
    fi
  else
    HEAP_MB=614
  fi
  export OMNIROUTE_MEMORY_MB="$HEAP_MB"
  export NODE_OPTIONS="--max-old-space-size=$HEAP_MB"
fi

# ── App start ──────────────────────────────────────────────────────────────
# Runs as root (USER root): Railway mounts volumes root-owned, and uid 1000
# cannot write them -> fatal EACCES on the SQLite dir. Root matches the
# official upstream template behavior on Railway.
mkdir -p "${DATA_DIR:-/app/data}" 2>/dev/null || true
# Runs as root (USER root), so the root-owned Railway volume is writable and no
# separate permission-fix helper is needed. Exec the app CMD directly.
exec "$@"