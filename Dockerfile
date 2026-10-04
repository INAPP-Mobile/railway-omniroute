# Pinned: upstream Docker publishes are flaky (v3.8.50 never landed on Docker
# Hub) and Dependabot skips :latest, so a float silently rots. Verify the tag
# exists at https://hub.docker.com/r/diegosouzapw/omniroute/tags and boots
# before bumping.
FROM diegosouzapw/omniroute:3.8.51

# Adaptive heap sizing (verified 2026-10-04 via cgroup-limit podman runs):
# - upstream bakes OMNIROUTE_MEMORY_MB=1024 with a matching
#   NODE_OPTIONS=--max-old-space-size=1024, regardless of the service's real
#   memory cap
# - measured idle RSS: 514MB on 3.8.50, 361MB on 3.8.51. A 0.5GB service cap
#   leaves ~40MB of headroom on 3.8.50 before the first dashboard render, so
#   any allocation spike crosses the cgroup limit -> OOM-kill -> restart ->
#   healthcheck FAIL. That is the dominant template failure mode.
# - entrypoint derives heap from the container's cgroup memory limit (60%)
#   with a 614MB floor, so Hobby/Pro services use their full allowance — an
#   explicitly-passed OMNIROUTE_MEMORY_MB (e.g. via the template form) wins.
#   Blank the upstream-baked value first so the entrypoint can tell the
#   difference between baked and user-provided. NODE_OPTIONS must be blanked
#   too: it pins --max-old-space-size=1024, and with it left in place
#   run-standalone.mjs logs "heap limit conflict" on every boot (measured) and
#   the effective heap depends on flag-append order rather than the value the
#   entrypoint actually computed for the service's memory limit.
ENV OMNIROUTE_MEMORY_MB=""
ENV NODE_OPTIONS=""
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