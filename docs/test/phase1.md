# Phase 1 테스트 — 기본 Docker 구성

## 준비

```bash
cp .env.example .env
```

`.env` 파일 내용 확인 (기본값 그대로 사용 가능):

```env
PB_VERSION=0.22.4
PB_ADMIN_EMAIL=admin@example.com
PB_ADMIN_PASSWORD=changeme
```

## 실행

```bash
make up
```

## 검증 체크리스트

### 1. 컨테이너 상태

```bash
docker compose -f compose/docker-compose.yml ps
```

`STATUS` 컬럼이 `healthy`인지 확인. `starting`이면 10초 정도 대기 후 재확인.

### 2. 헬스체크 API

```bash
curl http://localhost:8090/api/health
```

예상 응답:

```json
{"code":200,"message":"API is healthy."}
```

### 3. Admin UI 로그인

브라우저에서 `http://localhost:8090/_/` 접속 후 `.env`에 설정한 이메일/비밀번호로 로그인 가능한지 확인.

### 4. 로그 확인

```bash
make logs
```

`superuser upsert` 실행 로그와 `Server started` 메시지 확인.

### 5. 컨테이너 접속

```bash
make shell
# 컨테이너 내부에서
ls /pb/pb_data
ls /pb/pb_migrations
ls /pb/pb_hooks
```

## 종료

```bash
make down
```
