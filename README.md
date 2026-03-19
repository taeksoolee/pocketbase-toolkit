# pocketbase-toolkit

PocketBase를 서버에 바로 배포할 수 있는 Docker 기반 툴킷.
백업, 복원, 업그레이드, 배포 자동화까지 포함한 재사용 가능한 템플릿이다.

---

## 특징

- **포트 개방 불필요** — Cloudflare Tunnel로 방화벽 뒤 서버에서도 HTTPS 배포 가능
- **데이터 안전** — PocketBase API 기반 백업 + 자동 스케줄 + S3 업로드 옵션
- **안전한 업그레이드** — 백업 → 버전업 → 헬스체크 → 실패 시 자동 롤백
- **단순한 배포** — `make deploy` 한 번으로 서버 업데이트

---

## 네트워크 구성

### 기본: Cloudflare Tunnel

서버의 포트를 외부에 열 필요 없이 Cloudflare를 통해 HTTPS로 노출한다.

```
인터넷 사용자
     │  HTTPS
     ▼
Cloudflare Edge (HTTPS 종단, DDoS 방어)
     │  터널 (암호화)
     ▼
cloudflared 컨테이너 (서버 내부)
     │  HTTP
     ▼
PocketBase 컨테이너 (8090)
```

**전제 조건:**
- Cloudflare에 도메인 등록
- Cloudflare Zero Trust에서 터널 생성 후 토큰 발급

### 대안: Caddy

Cloudflare 없이 VPS에 직접 배포할 때 사용한다. 서버의 공인 IP와 80/443 포트 개방이 필요하다.

---

## 빠른 시작

### 로컬

```bash
cp .env.example .env
# .env 편집
make up
# http://localhost:8090/_/ 접속
```

### 프로덕션 (Cloudflare Tunnel)

```bash
cp .env.example .env
# .env에 CF_TUNNEL_TOKEN, DOMAIN 입력
make deploy
# https://DOMAIN/_/ 접속
```

### 프로덕션 (Caddy)

```bash
cp .env.example .env
# .env에 DOMAIN 입력, 서버 80/443 포트 개방
make deploy-caddy
# https://DOMAIN/_/ 접속
```

---

## Make 명령어

| 명령어 | 설명 |
|--------|------|
| `make up` | 로컬 실행 |
| `make down` | 컨테이너 종료 |
| `make logs` | 로그 출력 |
| `make shell` | PocketBase 컨테이너 접속 |
| `make prod-up` | 프로덕션 실행 (Cloudflare Tunnel) |
| `make prod-down` | 프로덕션 종료 |
| `make deploy` | 서버 배포 |
| `make deploy-caddy` | 서버 배포 (Caddy) |
| `make backup` | 수동 백업 실행 |
| `make restore` | 백업 복원 |
| `make upgrade` | PocketBase 버전 업그레이드 |

---

## 디렉토리 구조

```
pocketbase-toolkit/
├── docker/
│   ├── Dockerfile              # PocketBase 이미지
│   └── Dockerfile.extend       # Go 확장용 (선택)
├── compose/
│   ├── docker-compose.yml      # 로컬
│   ├── docker-compose.prod.yml # 프로덕션 (Cloudflare Tunnel)
│   └── docker-compose.caddy.yml # 대안 (Caddy)
├── caddy/
│   └── Caddyfile
├── pb_migrations/              # 마이그레이션 파일
├── pb_hooks/                   # JS 훅
├── scripts/
│   ├── backup.sh
│   ├── restore.sh
│   ├── upgrade.sh
│   └── deploy.sh
├── .env.example
├── Makefile
└── README.md
```

---

## 환경변수

`.env.example`을 복사해서 사용한다.

```env
# PocketBase
PB_VERSION=0.22.4
PB_ADMIN_EMAIL=admin@example.com
PB_ADMIN_PASSWORD=changeme

# Cloudflare Tunnel
CF_TUNNEL_TOKEN=

# 도메인
DOMAIN=example.com

# 백업 (선택)
BACKUP_S3_BUCKET=
BACKUP_S3_REGION=
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
BACKUP_RETENTION_DAYS=7

# 배포
DEPLOY_HOST=
DEPLOY_USER=
DEPLOY_PATH=/opt/pocketbase
```

---

## 기술 스택

| 역할 | 선택 |
|------|------|
| 백엔드 | PocketBase |
| 컨테이너 | Docker + Compose |
| 외부 노출 (기본) | Cloudflare Tunnel |
| 외부 노출 (대안) | Caddy |
| 백업 스케줄 | ofelia |
| 배포 | SSH + shell script |

---

## 적합한 사용 사례

- 사이드 프로젝트 / 개인 서비스
- 프로토타입 또는 MVP
- 소규모 팀 내부 도구
- Supabase, Firebase 대신 셀프호스팅을 원하는 경우

## 한계

- SQLite 특성상 수평 확장 불가, 고트래픽 서비스에는 부적합
- 기본 구성이 Cloudflare에 의존하므로 Cloudflare 장애 시 접근 불가
- 로그 수집, 메트릭, 알림 등 운영 가시성 도구 미포함

---

## 라이센스

MIT
