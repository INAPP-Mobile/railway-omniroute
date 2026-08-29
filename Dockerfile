# Pinned: upstream Docker publishes are flaky (v3.8.50 never landed on Docker
# Hub) and Dependabot skips :latest, so a float silently rots. Verify the tag
# exists at https://hub.docker.com/r/diegosouzapw/omniroute/tags and boots
# before bumping.
FROM diegosouzapw/omniroute:3.8.49

# Adaptive heap sizing (verified 2026-08-29 via cgroup OOM tests):
# - upstream bakes OMNIROUTE_MEMORY_MB=1024; idle RSS ~595MB spikes past 1GB on
#   first dashboard render -> cgroup OOM-kill -> restart loop -> healthcheck FAIL
# - 614 heap is the verified floor for boot + full dashboard render within a
#   1GB service cap (Railway Trial); 512MB plans cannot fit this app at all
# - entrypoint derives heap from the container's cgroup memory limit (60%) with
#   a 614MB floor, so Hobby/Pro services use their full allowance — an
#   explicitly-passed OMNIROUTE_MEMORY_MB (e.g. via the template form) wins.
#   Blank the upstream-baked value first so the entrypoint can tell the
#   difference between baked and user-provided.
ENV OMNIROUTE_MEMORY_MB=""
COPY --chmod=0755 railway-entrypoint.sh /usr/local/bin/railway-entrypoint.sh

# OmniRoute runs on port 20128 by default
EXPOSE 20128

# Entrypoint runs as root: Railway mounts volumes root-owned, and uid 1000
# cannot write them -> fatal EACCES on the SQLite dir. This matches the
# official upstream template behavior (equivalent of RAILWAY_RUN_UID=0). The
# entrypoint also derives the V8 heap from the cgroup limit. See
# railway-entrypoint.sh.
USER root
ENTRYPOINT ["/usr/local/bin/railway-entrypoint.sh"]
CMD ["node", "dev/run-standalone.mjs"]

# Healthcheck for Railway deployment
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD ["node", "healthcheck.mjs"]