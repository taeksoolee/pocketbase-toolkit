# PocketBase Toolkit - 아키텍처 및 구현 계획

## 프로젝트 목표

PocketBase를 서버에 바로 배포할 수 있는 Docker 기반 툴킷.
반복적으로 사용 가능한 배포 템플릿을 목표로 한다.

---

## 실현 가능성 판단

**가능 여부: O (높음)**

PocketBase는 Go 단일 바이너리로 Alpine Linux 기반 Docker 이미지를 10MB 수준으로 만들 수 있다.
SQLite 파일 하나로 데이터를 관리하므로 볼륨 마운트만으로 영속성 확보가 된다.
HTTPS, 백업, 마이그레이션까지 구성하면 재사용 가능한 배포 템플릿으로 가치가 있다.

---

## 네트워크 구성 전략

### 기본: Cloudflare Tunnel

`cloudflared` 컨테이너가 Cloudflare로 **아웃바운드 연결**을 맺는 방식.
서버의 포트를 외부에 열 필요가 없어 방화벽/보안 설정이 단순하다.

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

**장점:**
- 서버 포트 개방 불필요 (80, 443 닫아도 됨)
- 공인 IP 없는 홈서버에서도 동작
- HTTPS는 Cloudflare가 처리 → 인증서 관리 불필요
- DDoS 방어, WAF, Bot 차단 기본 제공
- Cloudflare 무료 플랜으로 충분

**전제 조건:**
- Cloudflare에 도메인 등록
- Cloudflare Zero Trust 터널 토큰 발급

### 대안: Caddy (선택)

Cloudflare 없이 VPS에 직접 배포할 때 사용하는 Reverse Proxy.
Let's Encrypt로 SSL 인증서를 자동 발급/갱신한다.
서버의 공인 IP와 80/443 포트 개방이 필요하다.

> Cloudflare Tunnel을 사용한다면 Caddy는 불필요하다.

---

## 최종 디렉토리 구조

```
pocketbase-toolkit/
├── docker/
│   ├── Dockerfile              # PocketBase 이미지 빌드
│   └── Dockerfile.extend       # Go 훅 확장용 (선택)
├── compose/
│   ├── docker-compose.yml      # 기본 구성 (로컬)
│   ├── docker-compose.prod.yml # 프로덕션: Cloudflare Tunnel 포함
│   └── docker-compose.caddy.yml # 대안: Caddy HTTPS (Cloudflare 미사용 시)
├── caddy/
│   └── Caddyfile               # Caddy 대안 구성용
├── pb_migrations/              # PocketBase 마이그레이션 파일
├── pb_hooks/                   # PocketBase JS 훅
├── scripts/
│   ├── backup.sh               # SQLite 백업 스크립트
│   ├── restore.sh              # 백업 복원
│   └── deploy.sh               # 서버 배포 스크립트
├── .env.example                # 환경변수 템플릿
├── Makefile                    # 자주 쓰는 명령어 모음
└── README.md
```

---

## 구현 단계

### Phase 1 — 기본 Docker 구성

**목표:** PocketBase를 Docker로 로컬에서 실행

- [ ] `docker/Dockerfile` 작성
  - `alpine:3.19` 기반
  - PocketBase 공식 릴리즈 바이너리 다운로드
  - 버전은 ARG로 지정 가능하게
- [ ] `compose/docker-compose.yml` 작성
  - `pb_data` 볼륨으로 데이터 영속성
  - 포트: `8090` (로컬 전용)
- [ ] `.env.example` 작성
  - `PB_VERSION`, `PB_ADMIN_EMAIL`, `PB_ADMIN_PASSWORD` 등
- [ ] `Makefile` 기본 타겟
  - `make up`, `make down`, `make logs`, `make shell`

**검증 기준:** `make up` 후 `localhost:8090/_/` Admin UI 접근 가능

---

### Phase 2 — Cloudflare Tunnel 연동

**목표:** 서버 포트 개방 없이 HTTPS로 외부 접근

- [ ] `compose/docker-compose.prod.yml` 작성
  - `cloudflare/cloudflared` 컨테이너 추가
  - PocketBase와 같은 내부 네트워크에 배치
  - 외부 포트 노출 없음 (80, 443 불필요)
  - PocketBase에 Docker healthcheck 추가 (`/api/health` 엔드포인트)
  - `cloudflared`는 `depends_on: condition: service_healthy`로 PocketBase 완전 기동 후 연결
- [ ] `.env.example`에 `CF_TUNNEL_TOKEN` 추가
- [ ] `Makefile`에 `make prod-up`, `make prod-down` 타겟 추가
- [ ] README에 Cloudflare Zero Trust 터널 발급 방법 안내

**검증 기준:** `https://DOMAIN/_/` 으로 Admin UI 접근 가능

> **대안 (Caddy):** Cloudflare 없이 VPS 직접 배포 시 `compose/docker-compose.caddy.yml` + `caddy/Caddyfile` 사용.
> 서버의 공인 IP와 80/443 포트 개방 필요.

---

### Phase 3 — 백업, 복원 및 업그레이드

**목표:** SQLite 데이터 유실 방지

- [ ] `scripts/backup.sh` 작성
  - `pb_data/data.db`를 타임스탬프 기반 파일로 복사
  - S3 업로드 옵션 (aws cli, 선택)
  - 보존 기간 설정 (기본 7일, 오래된 파일 자동 삭제)
- [ ] `scripts/restore.sh` 작성
  - 백업 파일 목록 출력 후 선택 복원
- [ ] `compose/docker-compose.prod.yml`에 cron 백업 서비스 추가
  - `mcuadros/ofelia` 또는 `busybox crond` 기반
- [ ] `scripts/upgrade.sh` 작성
  - 업그레이드 순서: 백업 → `PB_VERSION` 변경 → 재시작 → `/api/health` 확인
  - 헬스체크 실패 시 자동 롤백 (이전 버전으로 재시작)
- [ ] `Makefile`에 `make upgrade` 타겟 추가

**검증 기준:** 백업 파일 생성 확인, 복원 후 데이터 정합성 확인, 버전업 후 서비스 정상 동작 확인

---

### Phase 4 — 배포 자동화

**목표:** `make deploy`로 서버 배포

- [ ] `scripts/deploy.sh` 작성
  - SSH로 서버 접속
  - `git pull` 또는 파일 복사
  - `docker compose pull && docker compose up -d`
  - 헬스체크 후 결과 출력
- [ ] `Makefile`에 `make deploy` 타겟 추가
- [ ] GitHub Actions 워크플로우 (선택)
  - `main` 브랜치 push 시 자동 배포

**검증 기준:** 로컬에서 `make deploy` 한 번으로 서버 업데이트

---

### Phase 5 — 커스텀 훅/확장 (선택)

**목표:** PocketBase JS 훅 또는 Go 확장 지원

- [ ] `pb_hooks/` 예시 훅 파일 추가
  - 이메일 발송 훅 예시
  - 레코드 생성 전 유효성 검사 예시
- [ ] `docker/Dockerfile.extend` 작성 (선택)
  - Go로 PocketBase 커스텀 빌드
  - 추가 플러그인 포함 가능

---

## 기술 스택

| 역할 | 선택 | 비고 |
|------|------|------|
| 백엔드 | PocketBase | 단일 바이너리, SQLite, 올인원 |
| 컨테이너 | Docker + Compose | 표준, 간단 |
| 외부 노출 (기본) | Cloudflare Tunnel | 포트 개방 불필요, HTTPS 자동 |
| 외부 노출 (대안) | Caddy | Cloudflare 미사용 시, 공인 IP 필요 |
| 백업 스케줄 | ofelia (cron) | Docker-native cron |
| 배포 | SSH + shell script | 의존성 없음, 단순 |

---

## 환경변수 목록 (.env.example 기준)

```env
# PocketBase
PB_VERSION=0.22.4
PB_ADMIN_EMAIL=admin@example.com
PB_ADMIN_PASSWORD=changeme

# Cloudflare Tunnel (프로덕션 기본)
CF_TUNNEL_TOKEN=

# 서버 도메인
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

## 시작 순서 (로컬)

```bash
cp .env.example .env
# .env 편집
make up
# http://localhost:8090/_/ 접속
```

## 시작 순서 (프로덕션 — Cloudflare Tunnel)

```bash
cp .env.example .env
# .env에 CF_TUNNEL_TOKEN, DOMAIN 입력
make deploy
# https://DOMAIN/_/ 접속
```

## 시작 순서 (프로덕션 — Caddy 대안)

```bash
cp .env.example .env
# .env에 DOMAIN 입력, 서버 80/443 포트 개방
make deploy-caddy
# https://DOMAIN/_/ 접속
```
