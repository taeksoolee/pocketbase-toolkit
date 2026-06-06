# pocketbase-toolkit

PocketBase를 Docker 기반으로 운영하기 위한 배포 템플릿이다.
핵심 목표는 다음 3가지다.

- 포크 저장소(private)에서 바로 배포 가능한 구조
- 업스트림 변경 반영 시 CI/CD로 자동 재배포 가능한 구조
- 재배포가 발생해도 데이터(볼륨) 유지가 가능한 구조

---

## 운영 관점 핵심 요약

- 기본 배포 경로는 Cloudflare Tunnel 기반이며 서버 포트 개방 없이 HTTPS 노출 가능
- Admin 계정은 컨테이너 시작 시 자동 생성하지 않고, 명령으로 명시적으로 동기화
- 배포 자동화는 GitHub Actions에서 수행하며, 서버의 `.env`를 기준으로 환경 유지
- 일반 배포/재배포는 볼륨을 삭제하지 않으므로 PocketBase 데이터가 유지됨

---

## 운영 시나리오 (권장)

### 1) 템플릿 포크 후 private 전환

1. 이 저장소를 포크
2. 포크 저장소를 private로 전환
3. 서버 1대 준비 (Docker/Compose 설치)

### 2) 최초 1회 배포 (환경 안착)

```bash
cp .env.example .env
# .env에 CF_TUNNEL_TOKEN, DOMAIN, DEPLOY_HOST, DEPLOY_USER 등 입력
make deploy
```

최초 1회 배포에서 서버에 `.env`가 전달되고, 이후 자동 배포는 서버의 `.env`를 계속 사용한다.

### 3) Admin 계정 동기화

```bash
make sync-admin
# 또는 로컬 개발 시
make up-sync-admin
```

### 4) 이후 운영

- 포크 저장소의 `main`에 push하면 CI/CD가 자동 배포
- 업스트림 원본 저장소 변경을 포크에 동기화하면 동일하게 자동 배포
- 재배포가 발생해도 볼륨 삭제가 없으면 데이터는 유지

---

## 데이터 유지 원칙 (중요)

다음 조건을 지키면 재배포 시 데이터는 유지된다.

- PocketBase 데이터는 Docker 볼륨(`pb_data`)에 저장
- 일반 배포는 `down --volumes`를 사용하지 않음
- `make deploy`, `make prod-up`, CI/CD 재배포는 볼륨을 유지하는 경로

데이터가 삭제되는 경우:

- `make reset`
- `make prod-reset`
- 수동으로 볼륨을 삭제한 경우

즉, 운영 환경에서는 reset 계열 명령 사용 전 반드시 백업을 먼저 수행해야 한다.

---

## 계정 용어 정리

- Admin = Superuser (동일 개념)
: PocketBase Admin UI(`/_/`)에 로그인하는 운영자 계정
- User (Auth 컬렉션 레코드)
: 앱 사용자 계정이며 Admin 계정과는 별개

이 프로젝트의 `.env` `PB_ADMIN_EMAIL`, `PB_ADMIN_PASSWORD`는 Admin 계정을 의미한다.

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

전제 조건:

- Cloudflare에 도메인 등록
- Cloudflare Zero Trust > Networks > Tunnels에서 터널 생성 후 토큰 발급
- Public Hostname: `example.com` -> Service: `http://pocketbase:8090`

### 대안: Caddy

Cloudflare 없이 VPS에 직접 배포할 때 사용한다.
서버의 공인 IP와 80/443 포트 개방이 필요하다.

---

## 빠른 시작

### 로컬

```bash
cp .env.example .env
# .env 편집 (PB_HOST_PORT 등)
make up-sync-admin
# http://localhost:${PB_HOST_PORT:-8090}/_/
```

또는 단계별 실행:

```bash
make up
make sync-admin
```

### 프로덕션 (Cloudflare Tunnel)

```bash
cp .env.example .env
# .env에 CF_TUNNEL_TOKEN, DOMAIN, DEPLOY_HOST, DEPLOY_USER 입력
make deploy
# https://DOMAIN/_/
```

### 프로덕션 (Caddy)

```bash
cp .env.example .env
# .env에 DOMAIN, DEPLOY_HOST, DEPLOY_USER 입력 / 서버 80/443 포트 개방
make deploy-caddy
# https://DOMAIN/_/
```

---

## CI/CD 및 포크 운영

### 배포 흐름

```text
PR        -> lint + Docker 빌드 검증 (배포 없음)
main push -> lint + Docker 빌드 검증 -> 자동 배포
```

### GitHub Secrets

포크 저장소의 Settings -> Secrets and variables -> Actions에 아래 항목 등록:

- `DEPLOY_SSH_KEY`: SSH private key (`~/.ssh/id_ed25519` 내용)
- `DEPLOY_HOST`: 서버 IP 또는 도메인
- `DEPLOY_USER`: SSH 접속 계정
- `DEPLOY_PATH`: 서버 배포 경로 (예: `/opt/pocketbase`)

`CF_TUNNEL_TOKEN` 등 앱 설정값은 최초 배포 시 서버 `.env`에 반영되며, 이후 서버 `.env`를 유지해도 된다.

### 업스트림 반영

업스트림 변경을 포크 저장소 `main`에 반영하면 워크플로우가 재실행되고, 서버 환경이 업데이트된다.
이때 볼륨을 삭제하지 않으면 데이터는 유지된다.

---

## Make 명령어

| 명령어 | 설명 |
|--------|------|
| `make up` | 로컬 실행 |
| `make down` | 컨테이너 종료 |
| `make reset` | 로컬 완전 초기화 후 재기동 (컨테이너/이미지/볼륨 삭제) |
| `make logs` | 로그 출력 |
| `make shell` | PocketBase 컨테이너 접속 |
| `make prod-up` | 프로덕션 로컬 실행 (Cloudflare Tunnel + ofelia) |
| `make prod-down` | 프로덕션 종료 |
| `make prod-clean` | 프로덕션 컨테이너 종료 + 관련 이미지 제거 (재기동 없음) |
| `make prod-reset` | 프로덕션 완전 초기화 후 재기동 (컨테이너/이미지/볼륨 삭제) |
| `make deploy` | SSH로 서버 배포 (Cloudflare Tunnel) |
| `make deploy-caddy` | SSH로 서버 배포 (Caddy) |
| `make backup` | 수동 백업 실행 |
| `make db-snapshot` | 디버깅용 DB 스냅샷 ZIP 생성 (`./snapshots`) |
| `make restore` | 백업 목록에서 선택하여 복원 |
| `make upgrade VERSION=x.x.x` | PocketBase 버전 업그레이드 (실패 시 자동 롤백) |
| `make create-admin` | Admin(UI) 계정 생성 인터랙티브 실행 |
| `make make-admin` | `make create-admin` 별칭 |
| `make sync-admin` | `.env` Admin 정보로 create/update 동기화 |
| `make up-sync-admin` | `make up` 후 `make sync-admin` 실행 |
| `make create-admin EMAIL=admin2@example.com PASSWORD='...'` | Admin(UI) 계정 생성 비인터랙티브 실행 |
| `make create-account` | 레거시 별칭 (`make create-admin`으로 연결) |
| `make make-account` | 레거시 별칭 (`make create-admin`으로 연결) |
| `make list-admins` | Admin(UI) 계정 목록 조회 |

`make db-snapshot`와 `make list-admins`는 `.env`의 `PB_ADMIN_EMAIL`, `PB_ADMIN_PASSWORD`를 사용한다.

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

운영 권장:

```bash
make sync-admin
```

서버 기동과 계정 동기화를 한 번에:

```bash
make up-sync-admin
```

대화형 수동 생성:

```bash
make create-admin
# 또는: make make-admin
```

비인터랙티브 생성:

```bash
make create-admin EMAIL=admin@example.com PASSWORD='your-password'
```

---

## 백업 / 복원 / 업그레이드

### 수동 백업

```bash
make backup
# ./backups/backup_YYYYMMDD_HHMMSS.zip 생성
```

### 자동 백업 (프로덕션)

`make prod-up` 또는 `make deploy` 실행 시 ofelia 컨테이너가 함께 기동되며 매일 새벽 2시에 자동 백업이 실행된다.

### 복원

```bash
make restore
# 백업 목록 출력 -> 번호 선택 -> 복원 실행
```

### 업그레이드

```bash
make upgrade VERSION=0.23.0
```

순서: 백업 -> `PB_VERSION` 변경 -> 컨테이너 재빌드 -> 헬스체크(최대 60초) -> 실패 시 이전 버전 자동 롤백

---

## 디렉토리 구조

```text
pocketbase-toolkit/
├── .claude/
│   └── settings.local.json
├── .github/
│   └── workflows/
│       └── ci-cd.yml
├── caddy/
│   └── Caddyfile
├── compose/
│   ├── docker-compose.caddy.yml
│   ├── docker-compose.prod.yml
│   └── docker-compose.yml
├── docker/
│   ├── Dockerfile
│   ├── Dockerfile.extend
│   └── entrypoint.sh
├── docs/
│   ├── deployment.md
│   ├── evaluation.md
│   ├── manual/
│   │   ├── cloudflare-tunnel.md
│   │   ├── make.md
│   │   └── pocketbase.md
│   ├── plan/
│   └── test/
├── extend/
│   └── main.go
├── pb_hooks/
├── pb_migrations/
├── scripts/
│   ├── backup.sh
│   ├── create_admin.sh
│   ├── db_snapshot.sh
│   ├── list_admins.sh
│   ├── restore.sh
│   ├── sync_admin_from_env.sh
│   ├── upgrade.sh
│   └── deploy.sh
├── .env.example
├── .gitignore
├── Makefile
└── README.md
```

---

## 커스텀 훅 (JS)

`pb_hooks/*.pb.js` 파일을 추가하면 PocketBase가 자동으로 로드한다. 재시작 불필요.

---

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
