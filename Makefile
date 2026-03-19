.PHONY: up down logs shell prod-up prod-down

COMPOSE       = docker compose -f compose/docker-compose.yml
COMPOSE_PROD  = docker compose -f compose/docker-compose.yml -f compose/docker-compose.prod.yml
COMPOSE_CADDY = docker compose -f compose/docker-compose.yml -f compose/docker-compose.caddy.yml

# ── 로컬 ──────────────────────────────────────────────────────────────────────

up:
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

logs:
	$(COMPOSE) logs -f

shell:
	$(COMPOSE) exec pocketbase sh

# ── 프로덕션 (Cloudflare Tunnel) ───────────────────────────────────────────────

prod-up:
	$(COMPOSE_PROD) up -d --build

prod-down:
	$(COMPOSE_PROD) down
