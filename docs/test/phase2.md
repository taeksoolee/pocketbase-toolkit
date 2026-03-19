# Phase 2 테스트 — Cloudflare Tunnel / Caddy 연동

## 옵션 A: Cloudflare Tunnel

### 전제 조건

- Cloudflare에 도메인 등록
- Cloudflare Zero Trust > Networks > Tunnels에서 터널 생성
  - Connector: Docker
  - Public Hostname: `example.com` → Service: `http://pocketbase:8090`
  - 터널 생성 후 **토큰(Token)** 복사

### 준비

```bash
# .env에 CF_TUNNEL_TOKEN, DOMAIN 설정
CF_TUNNEL_TOKEN=<발급받은 토큰>
DOMAIN=example.com
```

### 실행

```bash
make prod-up
```

### 검증 체크리스트

```bash
# 컨테이너 상태 확인 (pocketbase: healthy, cloudflared: running)
docker compose -f compose/docker-compose.yml -f compose/docker-compose.prod.yml ps
```

1. `pocketbase` 컨테이너가 `healthy` 상태인지 확인
2. `cloudflared` 컨테이너가 `running` 상태인지 확인
3. `https://<DOMAIN>/_/` 브라우저 접속 → Admin UI 로그인 확인
4. HTTPS 인증서 정상 여부 확인 (브라우저 자물쇠 아이콘)

```bash
# cloudflared 로그에서 터널 연결 성공 메시지 확인
docker compose -f compose/docker-compose.yml -f compose/docker-compose.prod.yml logs cloudflared
# 예상: "Connection ... registered connIndex=0"
```

### 종료

```bash
make prod-down
```

---

## 옵션 B: Caddy (Cloudflare 미사용)

### 전제 조건

- 공인 IP가 있는 VPS
- 서버 방화벽에서 80, 443 포트 개방
- 도메인 DNS A 레코드가 서버 공인 IP를 가리킬 것

### 준비

```bash
# .env에 DOMAIN 설정
DOMAIN=example.com
```

### 실행

```bash
docker compose -f compose/docker-compose.yml -f compose/docker-compose.caddy.yml up -d --build
```

### 검증 체크리스트

```bash
# 컨테이너 상태 확인 (pocketbase: healthy, caddy: running)
docker compose -f compose/docker-compose.yml -f compose/docker-compose.caddy.yml ps
```

1. `caddy` 컨테이너 로그에서 Let's Encrypt 인증서 발급 확인
2. `https://<DOMAIN>/_/` 브라우저 접속 → Admin UI 로그인 확인

```bash
# Caddy 로그 확인
docker compose -f compose/docker-compose.yml -f compose/docker-compose.caddy.yml logs caddy
```
