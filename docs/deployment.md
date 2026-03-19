# 배포 전략

## 배포 방식 선택

이 툴킷은 두 가지 배포 방식을 지원한다.

| 방식 | 명령어 | 트리거 | 적합한 상황 |
|------|--------|--------|-------------|
| 수동 배포 | `make deploy` | 로컬에서 직접 실행 | 소규모 프로젝트, 단순 운영 |
| 자동 배포 | GitHub Actions | `main` 브랜치 push | 팀 협업, CI/CD 파이프라인 필요 시 |

두 방식 모두 동일한 `scripts/deploy.sh`를 실행한다. 차이는 트리거 주체뿐이다.

---

## 네트워크 노출 방식 선택

배포 전 아래 기준으로 네트워크 구성을 선택한다.

| 항목 | Cloudflare Tunnel | Caddy |
|------|------------------|-------|
| 공인 IP 필요 여부 | 불필요 | 필요 |
| 포트 개방 (80/443) | 불필요 | 필요 |
| HTTPS 인증서 | Cloudflare가 자동 처리 | Let's Encrypt 자동 발급 |
| DDoS 방어 / WAF | 기본 제공 | 없음 |
| Cloudflare 계정 필요 | 필요 | 불필요 |
| 홈서버 / 사설 IP | 가능 | 불가 |

**기본 권장: Cloudflare Tunnel.** 공인 IP 없는 서버, 보안 설정을 단순하게 유지하고 싶은 경우 적합하다.
**Caddy 선택:** Cloudflare 없이 VPS에 직접 배포하고 싶은 경우.

---

## 서버 사전 준비

배포 대상 서버에 아래 항목이 설치되어 있어야 한다.

```bash
# Docker
curl -fsSL https://get.docker.com | sh

# Docker Compose 플러그인 확인
docker compose version

# Git
apt install -y git   # Ubuntu/Debian
```

로컬 머신에서 SSH 키 기반 접속이 가능해야 한다:

```bash
# SSH 키 생성 (이미 있으면 생략)
ssh-keygen -t ed25519

# 서버에 공개 키 등록
ssh-copy-id $DEPLOY_USER@$DEPLOY_HOST

# 접속 확인
ssh $DEPLOY_USER@$DEPLOY_HOST "echo ok"
```

---

## 배포 흐름

### 최초 배포

```
로컬 .env 설정
     │
     ▼
make deploy (또는 GitHub Actions)
     │
     ▼
SSH 접속 → 서버에 git clone
     │
     ▼
.env 파일 서버로 전송 (최초 1회)
     │
     ▼
docker compose up -d --build
     │
     ▼
헬스체크 (/api/health) 최대 60초 대기
     │
  성공 ──→ 배포 완료
  실패 ──→ 로그 안내 후 종료
```

### 재배포 (코드 변경 후)

```
main 브랜치 push (또는 make deploy)
     │
     ▼
SSH 접속 → git pull
     │
     ▼
서버 .env 유지 (덮어쓰지 않음)
     │
     ▼
docker compose up -d --build
     │
     ▼
헬스체크 통과 → 배포 완료
```

> `.env`는 최초 배포 시에만 로컬에서 서버로 전송된다. 이후에는 서버의 `.env`를 직접 수정해야 한다.

---

## 수동 배포

### .env 설정

```env
DEPLOY_HOST=123.456.789.0
DEPLOY_USER=ubuntu
DEPLOY_PATH=/opt/pocketbase
```

### 실행

```bash
# Cloudflare Tunnel 모드
make deploy

# Caddy 모드
make deploy-caddy
```

---

## 자동 배포 (GitHub Actions)

### Secrets 등록

GitHub 저장소 → Settings → Secrets and variables → Actions:

| Secret | 값 |
|--------|-----|
| `DEPLOY_SSH_KEY` | SSH private key 전체 내용 (`cat ~/.ssh/id_ed25519`) |
| `DEPLOY_HOST` | 서버 IP 또는 도메인 |
| `DEPLOY_USER` | SSH 접속 계정 |
| `DEPLOY_PATH` | 서버 배포 경로 (예: `/opt/pocketbase`) |

### 트리거

`main` 브랜치에 push되면 자동으로 배포 워크플로우가 실행된다.

```bash
git push origin main
# GitHub Actions → deploy 워크플로우 자동 실행
```

GitHub → Actions 탭에서 실행 결과 확인 가능.

### Caddy 모드로 변경

`.github/workflows/deploy.yml`에서 배포 명령을 수정한다:

```yaml
- name: 배포 실행
  run: sh scripts/deploy.sh caddy   # cloudflare → caddy
```

---

## 롤백

### 코드 롤백

이전 커밋으로 되돌린 후 재배포한다:

```bash
git revert HEAD      # 되돌리는 커밋 생성
git push origin main # GitHub Actions 자동 배포 트리거
# 또는
make deploy          # 수동 배포
```

### 데이터 롤백

배포 전 백업이 있다면 복원한다:

```bash
make restore
# 백업 목록에서 배포 전 시점의 파일 선택
```

### PocketBase 버전 롤백

`upgrade.sh`는 헬스체크 실패 시 자동 롤백하지만, 수동으로 되돌릴 경우:

```bash
make upgrade VERSION=0.22.4   # 이전 버전으로 명시
```

---

## 운영 체크리스트

### 배포 전

- [ ] `make backup` 으로 현재 데이터 백업
- [ ] 변경 내용이 `main` 브랜치에 merge 완료
- [ ] 서버 SSH 접속 확인

### 배포 후

- [ ] 헬스체크 정상 확인: `curl https://DOMAIN/api/health`
- [ ] Admin UI 로그인 확인: `https://DOMAIN/_/`
- [ ] 주요 API 응답 확인

### 정기 운영

- [ ] 자동 백업 동작 확인 (ofelia 로그)
- [ ] 백업 파일 보존 기간 설정 (`BACKUP_RETENTION_DAYS`)
- [ ] PocketBase 신규 버전 릴리즈 확인 후 `make upgrade VERSION=x.x.x` 적용

---

## 장애 대응

### 컨테이너가 시작되지 않는 경우

```bash
ssh $DEPLOY_USER@$DEPLOY_HOST
cd $DEPLOY_PATH
docker compose -f compose/docker-compose.yml -f compose/docker-compose.prod.yml logs --tail=50
```

### Cloudflare Tunnel 연결 실패

```bash
# cloudflared 로그 확인
docker compose logs cloudflared

# CF_TUNNEL_TOKEN 값 확인
grep CF_TUNNEL_TOKEN .env
```

Cloudflare Zero Trust 대시보드에서 터널 상태 확인.

### 배포 후 데이터 이상

```bash
make restore
# 배포 전 백업 파일로 복원
```
