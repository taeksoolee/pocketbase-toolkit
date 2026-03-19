# Phase 4 테스트 — 배포 자동화

## 전제 조건

- SSH 접속 가능한 서버 (VPS, 홈서버 등)
- 서버에 Docker, Docker Compose, git, curl 설치
- 서버에서 이 저장소에 SSH 접근 가능 (GitHub Deploy Key 또는 HTTPS)

## 준비

`.env`에 배포 대상 서버 정보 입력:

```env
DEPLOY_HOST=123.456.789.0    # 서버 IP 또는 도메인
DEPLOY_USER=ubuntu           # SSH 접속 계정
DEPLOY_PATH=/opt/pocketbase  # 서버 배포 경로
```

SSH 키가 서버에 등록되어 있어야 한다:

```bash
# 로컬에서 SSH 접속 확인
ssh $DEPLOY_USER@$DEPLOY_HOST "echo ok"
```

---

## 배포 테스트 (Cloudflare Tunnel)

```bash
make deploy
```

예상 출력:
```
[deploy] 배포 시작: ubuntu@123.456.789.0:/opt/pocketbase (mode: cloudflare)
[deploy] 최초 배포 — 저장소 클론 중...   ← 최초 실행 시
[deploy] .env 전송 완료                   ← 최초 실행 시
[deploy] 컨테이너 재시작 중...
[deploy] 헬스체크 대기 중...
[deploy] 배포 완료
```

### 재배포 검증 (코드 변경 후)

```bash
# 변경사항 push 후
make deploy
```

두 번째 실행부터는:
```
[deploy] 저장소 업데이트 중...
[deploy] .env 이미 존재 — 서버 파일 유지
[deploy] 컨테이너 재시작 중...
[deploy] 배포 완료
```

---

## 배포 테스트 (Caddy)

```bash
make deploy-caddy
```

---

## GitHub Actions 자동 배포 테스트

### Secrets 등록

GitHub 저장소 → Settings → Secrets and variables → Actions:

| Secret 이름 | 값 |
|-------------|-----|
| `DEPLOY_SSH_KEY` | `~/.ssh/id_ed25519` 내용 (private key) |
| `DEPLOY_HOST` | 서버 IP 또는 도메인 |
| `DEPLOY_USER` | SSH 접속 계정 |
| `DEPLOY_PATH` | 서버 배포 경로 (예: `/opt/pocketbase`) |

### 트리거

`main` 브랜치에 push 시 자동 배포 실행.

```bash
git push origin main
```

GitHub → Actions 탭에서 워크플로우 실행 결과 확인.

---

## 헬스체크 실패 시

배포 후 헬스체크가 실패하면 서버에서 직접 로그를 확인한다:

```bash
ssh $DEPLOY_USER@$DEPLOY_HOST \
  "cd $DEPLOY_PATH && docker compose -f compose/docker-compose.yml -f compose/docker-compose.prod.yml logs --tail=50"
```
