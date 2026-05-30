---
name: docker-deployment-debug
description: Diagnose Docker/Nginx/deployment issues safely — container status, logs, health checks — without exposing secrets, deleting volumes, or assuming dev equals prod.
---

# Docker / Deployment Debug

## Commands (read-only diagnosis; Verifier runs these)
```txt
docker compose ps
docker compose logs --tail=100
curl -k https://localhost/api/health
curl -k http://localhost/api/health
```

## Hard rules
- Never expose secrets; never read `.env` / keys. `.env.example` uses placeholders only.
- **Never delete volumes** (`docker compose down -v`) without explicit written approval.
- Never assume dev and prod networks are identical. Production POS is static IP `192.168.1.32`;
  detect mismatches, do not silently rewrite.
- Summarize long logs but preserve exact error lines, container names, and ports.
