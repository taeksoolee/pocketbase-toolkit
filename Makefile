.PHONY: up down reset reset__danger logs shell prod-up prod-down prod-clean prod-reset prod-reset__danger backup restore upgrade deploy deploy-caddy create-admin make-admin create-account make-account sync-admin up-sync-admin db-snapshot list-admins

COMPOSE       = docker compose --env-file .env -f compose/docker-compose.yml
COMPOSE_PROD  = docker compose --env-file .env -f compose/docker-compose.yml -f compose/docker-compose.prod.yml
COMPOSE_CADDY = docker compose --env-file .env -f compose/docker-compose.yml -f compose/docker-compose.caddy.yml

# ── 로컬 ──────────────────────────────────────────────────────────────────────

up:
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

reset:
	@echo "[reset] 차단됨: 파괴적 명령입니다."
	@echo "[reset] 실행하려면: make reset__danger"
	@exit 1

reset__danger:
	$(COMPOSE) down --rmi all --volumes --remove-orphans
	docker builder prune -af
	$(COMPOSE) up -d --build --force-recreate

logs:
	$(COMPOSE) logs -f

shell:
	$(COMPOSE) exec pocketbase sh

# ── 프로덕션 (Cloudflare Tunnel) ───────────────────────────────────────────────

prod-up:
	$(COMPOSE_PROD) up -d --build

prod-down:
	$(COMPOSE_PROD) down

prod-clean:
	$(COMPOSE_PROD) down --rmi all --remove-orphans

prod-reset:
	@echo "[prod-reset] 차단됨: 파괴적 명령입니다."
	@echo "[prod-reset] 실행하려면: make prod-reset__danger"
	@exit 1

prod-reset__danger:
	$(COMPOSE_PROD) down --rmi all --volumes --remove-orphans
	docker builder prune -af
	$(COMPOSE_PROD) up -d --build --force-recreate

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

create-admin:
	@sh scripts/create_admin.sh "$(EMAIL)" "$(PASSWORD)"

make-admin: create-admin

create-account: create-admin

make-account: create-admin

sync-admin:
	@sh scripts/sync_admin_from_env.sh

up-sync-admin: up sync-admin

db-snapshot:
	@sh scripts/db_snapshot.sh

list-admins:
	@sh scripts/list_admins.sh
