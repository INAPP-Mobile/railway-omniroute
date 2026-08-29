# Deploy and Host

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.com/new/template/omniroute)

![OmniRoute OG Image](https://raw.githubusercontent.com/INAPP-Mobile/railway-omniroute/main/og-image.svg)

OmniRoute is a unified AI proxy that routes any LLM through a single OpenAI-compatible endpoint. Deploy it on Railway to manage multiple AI providers, enable compression pipelines, and optimize your LLM usage with intelligent routing and fallback strategies.

## About Hosting

OmniRoute runs as a single Docker container on port 20128. Railway provides compute, TLS at the edge, and a public URL. Data is stored in `/app/data` — add a Railway Volume there for persistence of your SQLite database, provider configurations, and usage logs.

## Why Deploy

- **Unified API** — Single OpenAI-compatible endpoint for all LLM providers
- **Provider Management** — Connect multiple AI providers with automatic failover
- **Compression Pipeline** — Reduce token usage with intelligent context compression
- **Model Aliases** — Create stable model names that route to different backends
- **Self-hosted** — Your API keys and usage data stay private
- **Real-time Dashboard** — Monitor usage, provider health, and routing decisions

## Common Use Cases

- **Multi-provider routing** — Route requests across OpenAI, Anthropic, Gemini, and more
- **Cost optimization** — Use compression and smart routing to reduce API costs
- **Fallback strategies** — Automatically switch providers when one is unavailable
- **Team access control** — Manage API keys and usage limits per user or project
- **Development proxy** — Test against multiple models without changing your code

## Dependencies for OmniRoute

### Deployment Dependencies

OmniRoute is a standalone service that requires no external dependencies on Railway. All data is stored in the container's `/app/data` directory using SQLite. Add a Railway Volume for persistent storage of your database, provider configurations, and usage logs.

**Memory requirement:** at least **1 GB RAM per service**. Use a Trial, Hobby, or Pro plan — the Free plan (0.5 GB) is below this app's boot footprint and will OOM-loop. The template pre-sizes the Node heap (`OMNIROUTE_MEMORY_MB=614`) so the dashboard UI can render within a 1 GB service limit without OOM kills.

---

# OmniRoute — Unified LLM Proxy & Router

> Route any LLM through one endpoint with intelligent provider management and compression.

## Features

- **Unified API** — Single OpenAI-compatible endpoint for all LLM providers
- **Multi-provider support** — Connect to OpenAI, Anthropic, Gemini, Claude, and 50+ providers
- **Compression pipelines** — Reduce token usage with factory, GPT-4o, Claude, and Gemini compressors
- **Model aliases** — Create stable model names that route to different backends
- **Composite routing** — Combine multiple providers with fallback strategies
- **Real-time monitoring** — Live dashboard showing usage, health, and routing decisions
- **API key management** — Create and rotate API keys with usage limits
- **Usage analytics** — Track token usage, costs, and provider performance
- **Rate limiting** — Built-in rate limiter (in-memory or Redis-backed)
- **Encryption at rest** — Optional SQLite encryption for sensitive data

## Quick Start

1. Click "Deploy on Railway" above
2. Configure the required secrets (JWT_SECRET, API_KEY_SECRET, INITIAL_PASSWORD)
3. Wait for deployment to complete
4. Access the dashboard at your Railway URL
5. Log in with your INITIAL_PASSWORD
6. Add providers via Dashboard → Providers
7. Create model aliases and composite routes
8. Use the `/v1/chat/completions` endpoint with your API key

## Configuration

### Required Secrets

- `JWT_SECRET` — JWT signing key for dashboard sessions (auto-generated)
- `API_KEY_SECRET` — Encryption key for stored API keys (auto-generated)
- `INITIAL_PASSWORD` — Initial admin login password (auto-generated, change after first login)

### Optional Configuration

- `DATA_DIR` — Data directory path (default: `/app/data`, must match volume mount)
- `PORT` — Service port (default: `20128`)
- `STORAGE_ENCRYPTION_KEY` — Enable SQLite encryption at rest
- `REQUIRE_API_KEY` — Require API key for all proxy requests
- `AUTH_COOKIE_SECURE` — Enable secure cookies (auto-detected on Railway)

### Advanced Options

- Split-port mode: Configure separate DASHBOARD_PORT and API_PORT
- WebSocket monitoring: Enable LIVE_WS_PORT for real-time dashboard updates
- Compression: Configure per-model compression pipelines via the dashboard
- Rate limiting: Adjust RELAY_IP_PER_MINUTE for request throttling

## API Usage

Once deployed, use OmniRoute as a drop-in replacement for the OpenAI API:

```bash
curl -X POST https://your-omniroute-url/v1/chat/completions \
  -H "Authorization: Bearer YOUR_OMNIROUTE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4o",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

## Provider Configuration

Add providers via the dashboard or API:

1. **Dashboard**: Navigate to Providers → Select provider → Enter API key
2. **API**: Use the management API endpoints for programmatic configuration

Supported providers include OpenAI, Anthropic, Google, Azure, AWS Bedrock, and 50+ others.

## Compression

Enable compression to reduce token usage:

1. Navigate to Compression in the dashboard
2. Create a compression pipeline (factory, GPT-4o, Claude, or Gemini)
3. Assign compression to specific models or providers
4. Monitor compression ratios in the analytics

## Monitoring

- **Dashboard**: Real-time usage, provider health, and routing decisions
- **API**: `/api/monitoring/health` for health checks
- **Logs**: Access via Railway's log viewer

## Data Persistence

OmniRoute uses SQLite for all persistence. The database includes:

- Provider connections and API keys
- Model aliases and composite routes
- Compression pipeline configurations
- Usage logs and analytics
- API keys and rate limits

All data is stored in `/app/data`. Add a Railway Volume for persistence across deployments.

## Security

- API keys are encrypted at rest using `API_KEY_SECRET`
- Dashboard sessions use JWT tokens signed with `JWT_SECRET`
- Optional SQLite encryption via `STORAGE_ENCRYPTION_KEY`
- Secure cookie support for HTTPS deployments
- Rate limiting to prevent abuse

## Links

- **Documentation**: [OmniRoute Docs](https://github.com/diegosouzapw/OmniRoute)
- **Source Code**: [GitHub Repository](https://github.com/diegosouzapw/OmniRoute)
- **Docker Hub**: [diegosouzapw/omniroute](https://hub.docker.com/r/diegosouzapw/omniroute)

## Support

For issues, feature requests, or questions, visit the [GitHub Issues](https://github.com/diegosouzapw/OmniRoute/issues) page.
