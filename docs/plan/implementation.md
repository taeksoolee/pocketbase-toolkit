# 구현 진행 현황

## Phase 1 — 기본 Docker 구성 [x]

> 목표: PocketBase를 Docker로 로컬에서 실행

- [x] `docker/Dockerfile`
- [x] `compose/docker-compose.yml`
- [x] `.env.example`
- [x] `Makefile` (up, down, logs, shell)

검증: `make up` → `http://localhost:8090/_/` 접근 가능

---

## Phase 2 — Cloudflare Tunnel 연동 [x]

> 목표: 서버 포트 개방 없이 HTTPS로 외부 접근

- [x] `compose/docker-compose.prod.yml` (cloudflared + healthcheck + depends_on)
- [x] `compose/docker-compose.caddy.yml` + `caddy/Caddyfile` (대안)
- [x] `.env.example`에 `CF_TUNNEL_TOKEN` 추가
- [x] `Makefile` (prod-up, prod-down)

검증: `https://DOMAIN/_/` 접근 가능

---

## Phase 3 — 백업, 복원 및 업그레이드 [x]

> 목표: SQLite 데이터 유실 방지 + 안전한 버전 업그레이드

- [x] `scripts/backup.sh` (PocketBase API 기반, S3 옵션)
- [x] `scripts/restore.sh`
- [x] `scripts/upgrade.sh` (백업 → 버전업 → 헬스체크 → 롤백)
- [x] `compose/docker-compose.prod.yml`에 cron 백업 서비스 추가 (ofelia, 매일 02:00)
- [x] `Makefile` (backup, restore, upgrade)

검증: 백업 생성, 복원 후 데이터 정합성, 버전업 후 정상 동작

---

## Phase 4 — 배포 자동화 [ ]

> 목표: `make deploy` 한 번으로 서버 배포

- [ ] `scripts/deploy.sh` (SSH → git pull → docker compose up -d → 헬스체크)
- [ ] `Makefile` (deploy, deploy-caddy)
- [ ] `.github/workflows/deploy.yml` (선택: main push 시 자동 배포)

검증: 로컬에서 `make deploy` 한 번으로 서버 업데이트

---

## Phase 5 — 커스텀 훅/확장 [ ] (선택)

> 목표: PocketBase JS 훅 또는 Go 확장 지원

- [ ] `pb_hooks/` 예시 파일 (이메일 발송, 유효성 검사)
- [ ] `docker/Dockerfile.extend` (Go 커스텀 빌드)

---

## 진행 기록

| Phase | 상태 | 완료일 |
|-------|------|--------|
| Phase 1 | 대기 | - |
| Phase 2 | 대기 | - |
| Phase 3 | 대기 | - |
| Phase 4 | 대기 | - |
| Phase 5 | 대기 | - |
