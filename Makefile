.PHONY: up down logs shell prod-up prod-down backup restore upgrade deploy deploy-caddy create-account db-snapshot

COMPOSE       = docker compose --env-file .env -f compose/docker-compose.yml
COMPOSE_PROD  = docker compose --env-file .env -f compose/docker-compose.yml -f compose/docker-compose.prod.yml
COMPOSE_CADDY = docker compose --env-file .env -f compose/docker-compose.yml -f compose/docker-compose.caddy.yml

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

# ── 배포 ────────────────────────────────────────────────────────────────────────

deploy:
	@sh scripts/deploy.sh cloudflare

deploy-caddy:
	@sh scripts/deploy.sh caddy

# ── 백업 / 복원 / 업그레이드 ────────────────────────────────────────────────────

backup:
	@sh scripts/backup.sh

restore:
	@sh scripts/restore.sh

upgrade:
	@if [ -z "$(VERSION)" ]; then echo "사용법: make upgrade VERSION=0.23.0"; exit 1; fi
	@sh scripts/upgrade.sh $(VERSION)

create-account:
	@sh scripts/create_account.sh "$(EMAIL)" "$(PASSWORD)"

db-snapshot:
	@sh scripts/db_snapshot.sh
