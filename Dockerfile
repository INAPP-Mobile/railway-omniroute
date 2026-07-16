FROM diegosouzapw/omniroute:latest

# OmniRoute runs on port 20128 by default
EXPOSE 20128

# Healthcheck for Railway deployment
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD ["node", "healthcheck.mjs"]
