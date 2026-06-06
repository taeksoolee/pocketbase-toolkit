# pocketbase-toolkit

PocketBase를 서버에 바로 배포할 수 있는 Docker 기반 툴킷.
백업, 복원, 업그레이드, 배포 자동화까지 포함한 재사용 가능한 템플릿이다.

---

## 특징

- **포트 개방 불필요** — Cloudflare Tunnel로 방화벽 뒤 서버에서도 HTTPS 배포 가능
- **Admin 계정 자동 생성** — `.env`의 `PB_ADMIN_EMAIL` / `PB_ADMIN_PASSWORD`로 최초 실행 시 자동 설정
- **데이터 안전** — PocketBase API 기반 백업 + ofelia 자동 스케줄(매일 02:00) + S3 업로드 옵션
- **안전한 업그레이드** — 백업 → 버전업 → 헬스체크 → 실패 시 자동 롤백
- **단순한 배포** — `make deploy` 한 번으로 서버 업데이트
- **확장 가능** — JS 훅 또는 Go 커스텀 빌드로 비즈니스 로직 추가 가능

---

## 계정 용어 정리

- **Admin = Superuser (동일 개념)**
     - PocketBase Admin UI(`/_/`)에 로그인 가능한 운영자 계정
     - 이 프로젝트의 `.env` `PB_ADMIN_EMAIL` / `PB_ADMIN_PASSWORD`는 이 Admin 계정을 의미
- **User (Auth 컬렉션 레코드)**
     - 앱 사용자 계정 (예: `users` 컬렉션)
     - Admin UI 로그인 계정과는 별개

즉, 이 프로젝트에서 `make create-account`는 **Admin(UI) 계정**을 생성/갱신한다.

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
- Cloudflare Zero Trust > Networks > Tunnels에서 터널 생성 후 토큰 발급
  - Public Hostname: `example.com` → Service: `http://pocketbase:8090`

### 대안: Caddy

Cloudflare 없이 VPS에 직접 배포할 때 사용한다. 서버의 공인 IP와 80/443 포트 개방이 필요하다.

---

## 빠른 시작

### 로컬

```bash
cp .env.example .env
# .env 편집 (PB_HOST_PORT, PB_ADMIN_EMAIL, PB_ADMIN_PASSWORD)
make up
# http://localhost:${PB_HOST_PORT:-8090}/_/ 접속 → .env 계정으로 로그인
```

### 프로덕션 (Cloudflare Tunnel)

```bash
cp .env.example .env
# .env에 CF_TUNNEL_TOKEN, DOMAIN, DEPLOY_HOST, DEPLOY_USER 입력
make deploy
# https://DOMAIN/_/ 접속
```

### 프로덕션 (Caddy)

```bash
cp .env.example .env
# .env에 DOMAIN, DEPLOY_HOST, DEPLOY_USER 입력 / 서버 80/443 포트 개방
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
| `make prod-up` | 프로덕션 로컬 실행 (Cloudflare Tunnel + ofelia) |
| `make prod-down` | 프로덕션 종료 |
| `make deploy` | SSH로 서버 배포 (Cloudflare Tunnel) |
| `make deploy-caddy` | SSH로 서버 배포 (Caddy) |
| `make backup` | 수동 백업 실행 |
| `make db-snapshot` | 디버깅용 DB 스냅샷 ZIP 생성 (`./snapshots`) |
| `make restore` | 백업 목록에서 선택하여 복원 |
| `make upgrade VERSION=x.x.x` | PocketBase 버전 업그레이드 (실패 시 자동 롤백) |
| `make create-account` | PocketBase Admin(UI) 계정 생성 인터랙티브 실행 |
| `make create-account EMAIL=admin2@example.com PASSWORD='...'` | PocketBase Admin(UI) 계정 생성 비인터랙티브 실행 |

`make db-snapshot`는 `.env`의 `PB_ADMIN_EMAIL`, `PB_ADMIN_PASSWORD`만 사용한다.

---

## 디렉토리 구조

```
pocketbase-toolkit/
├── .claude/
│   └── settings.local.json    # 로컬 개발 도구 설정
├── .github/
│   └── workflows/
│       └── ci-cd.yml           # CI(lint + 빌드 검증) + CD(main push 시 자동 배포)
├── caddy/
│   └── Caddyfile               # Caddy 리버스 프록시 설정
├── compose/
│   ├── docker-compose.caddy.yml # 대안 (Caddy)
│   ├── docker-compose.prod.yml # 프로덕션 (Cloudflare Tunnel + ofelia)
│   └── docker-compose.yml      # 로컬
├── docker/
│   ├── Dockerfile              # PocketBase 이미지
│   ├── Dockerfile.extend       # Go 커스텀 빌드용 (선택)
│   └── entrypoint.sh           # Admin 계정 자동 생성 + 서버 기동
├── docs/
│   ├── deployment.md           # 배포 상세 가이드
│   ├── evaluation.md           # 기획 평가
│   ├── manual/
│   │   ├── make.md             # Make 명령어 및 운영 루틴 매뉴얼
│   │   └── pocketbase.md       # PocketBase 기본 사용/운영 매뉴얼
│   ├── plan/                   # 아키텍처 및 구현 계획
│   └── test/                   # Phase별 테스트 방법
├── extend/
│   └── main.go                 # Go 확장 진입점 예시 (선택)
├── pb_hooks/                   # PocketBase JS 훅
│   ├── .gitkeep                # 빈 디렉토리 유지
│   ├── on_record_create_validate.pb.js   # 유효성 검사 예시
│   └── on_record_create_send_email.pb.js # 이메일 발송 예시
├── pb_migrations/              # PocketBase 마이그레이션 파일
│   └── .gitkeep                # 빈 디렉토리 유지
├── scripts/
│   ├── backup.sh               # PocketBase API 기반 백업
│   ├── create_account.sh       # PocketBase Admin(UI) 계정 생성/업데이트
│   ├── db_snapshot.sh          # 디버깅용 DB 스냅샷 생성
│   ├── restore.sh              # 백업 선택 복원
│   ├── upgrade.sh              # 버전 업그레이드 + 자동 롤백
│   └── deploy.sh               # SSH 배포 + 헬스체크
├── .env.example
├── .gitignore
├── Makefile
└── README.md
```

---

## 환경변수

`.env.example`을 복사해서 사용한다.

```env
# PocketBase
PB_VERSION=0.22.4
PB_HOST_PORT=8090
PB_ADMIN_EMAIL=admin@example.com
PB_ADMIN_PASSWORD=changeme

# Cloudflare Tunnel (프로덕션 기본)
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

`make up` 시 서버 기동 전에 Admin 계정 값이 먼저 검증된다.
- `PB_ADMIN_EMAIL`, `PB_ADMIN_PASSWORD`는 함께 설정해야 함
- `PB_ADMIN_EMAIL`은 이메일 형식이어야 함
- `PB_ADMIN_PASSWORD`는 최소 8자 이상이어야 함

---

## 백업

### 수동 백업

```bash
make backup
# ./backups/backup_YYYYMMDD_HHMMSS.zip 생성
```

### 자동 백업 (프로덕션)

`make prod-up` / `make deploy` 실행 시 ofelia 컨테이너가 함께 기동되며 **매일 새벽 2시**에 자동 백업이 실행된다.

### 복원

```bash
make restore
# 백업 목록 출력 → 번호 선택 → 복원 실행
```

---

## 업그레이드

```bash
make upgrade VERSION=0.23.0
```

순서: 백업 → `PB_VERSION` 변경 → 컨테이너 재빌드 → 헬스체크(최대 60초) → 실패 시 이전 버전으로 자동 롤백

---

## 배포 자동화

### GitHub Actions (CI/CD)

PR과 main push 시 CI가 실행되고, main push 시에는 CI 통과 후 자동으로 서버 배포까지 실행된다.

```
PR        →  lint + Docker 빌드 검증 (배포 없음)
main push →  lint + Docker 빌드 검증 → 배포
```

#### 1단계: 첫 배포는 로컬에서 실행

GitHub Actions에는 `.env` 파일이 없기 때문에 **최초 1회는 로컬에서 직접 배포**해야 한다.
이 과정에서 로컬 `.env`가 서버로 전송되고, 이후 GitHub Actions 배포에서는 서버의 `.env`를 그대로 사용한다.

```bash
cp .env.example .env
# .env에 CF_TUNNEL_TOKEN, DEPLOY_HOST, DEPLOY_USER 등 입력
make deploy          # 또는: sh scripts/deploy.sh cloudflare
```

#### 2단계: GitHub Secrets 등록

GitHub 저장소 → Settings → Secrets and variables → Actions에 아래 항목을 등록한다:

| Secret | 값 |
|--------|-----|
| `DEPLOY_SSH_KEY` | SSH private key (`~/.ssh/id_ed25519` 내용) |
| `DEPLOY_HOST` | 서버 IP 또는 도메인 |
| `DEPLOY_USER` | SSH 접속 계정 |
| `DEPLOY_PATH` | 서버 배포 경로 (예: `/opt/pocketbase`) |

> `CF_TUNNEL_TOKEN` 등 앱 설정값은 Secrets에 등록하지 않아도 된다. 1단계에서 서버에 전송된 `.env`를 계속 사용한다.

#### 이후 배포

`main` 브랜치에 push하면 CI 검증 후 자동 배포된다. 긴급 수동 배포가 필요할 때는 로컬에서 직접 실행해도 된다.

```bash
sh scripts/deploy.sh cloudflare   # 로컬 수동 배포
```

---

## 커스텀 훅 (JS)

`pb_hooks/*.pb.js` 파일을 추가하면 PocketBase가 자동으로 로드한다. 재시작 불필요.

```
pb_hooks/
├── on_record_create_validate.pb.js   # 레코드 생성 전 유효성 검사 예시
└── on_record_create_send_email.pb.js # 레코드 생성 후 이메일 발송 예시
```

## Go 확장 빌드 (선택)

외부 Go 패키지가 필요하거나 JS 훅으로 처리하기 어려운 경우 `extend/main.go`를 수정한 후 `docker/Dockerfile.extend`로 빌드한다.

```bash
docker build -f docker/Dockerfile.extend --build-arg PB_VERSION=0.22.4 -t pocketbase-custom .
```

---

## 기술 스택

| 역할 | 선택 | 비고 |
|------|------|------|
| 백엔드 | PocketBase | 단일 바이너리, SQLite, 올인원 |
| 컨테이너 | Docker + Compose | 표준, 간단 |
| 외부 노출 (기본) | Cloudflare Tunnel | 포트 개방 불필요, HTTPS 자동 |
| 외부 노출 (대안) | Caddy | Cloudflare 미사용 시, 공인 IP 필요 |
| 백업 스케줄 | ofelia | Docker-native cron |
| 배포 | SSH + shell script | 의존성 없음, 단순 |
| CI/CD | GitHub Actions | 선택 사항 |

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
