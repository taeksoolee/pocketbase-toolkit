.PHONY: up down logs shell

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
