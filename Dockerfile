# Pinned: upstream Docker publishes are flaky (v3.8.50 never landed on Docker
# Hub) and Dependabot skips :latest, so a float silently rots. Verify the tag
# exists at https://hub.docker.com/r/diegosouzapw/omniroute/tags and boots
# before bumping.
FROM diegosouzapw/omniroute:3.8.49

# OmniRoute runs on port 20128 by default
EXPOSE 20128

# Healthcheck for Railway deployment
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD ["node", "healthcheck.mjs"]
