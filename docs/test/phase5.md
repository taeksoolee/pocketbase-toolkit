# Phase 5 테스트 — 커스텀 훅 / Go 확장

## 옵션 A: JS 훅

PocketBase는 `pb_hooks/*.pb.js` 파일을 자동으로 로드한다.
별도 빌드 없이 파일만 추가하면 즉시 적용된다.

### 전제 조건

`make up`으로 PocketBase 실행 중.

### 유효성 검사 훅 테스트

`pb_hooks/on_record_create_validate.pb.js`는 `posts` 컬렉션 레코드 생성 시 `title` 길이를 검사한다.

**1. 컬렉션 생성**

Admin UI (`http://localhost:8090/_/`) → Collections → New Collection:
- Name: `posts`
- Fields: `title` (Text, Required)

**2. 유효성 검사 실패 케이스**

```bash
curl -s -X POST http://localhost:8090/api/collections/posts/records \
  -H "Content-Type: application/json" \
  -d '{"title": "짧"}'
```

예상 응답 (400):
```json
{"code":400,"message":"title은 최소 5자 이상이어야 합니다.","data":{}}
```

**3. 유효성 검사 통과 케이스**

```bash
curl -s -X POST http://localhost:8090/api/collections/posts/records \
  -H "Content-Type: application/json" \
  -d '{"title": "정상적인 제목입니다"}'
```

예상 응답 (200): 생성된 레코드 JSON

---

### 이메일 발송 훅 테스트

`pb_hooks/on_record_create_send_email.pb.js`는 `orders` 컬렉션 레코드 생성 시 이메일을 발송한다.

**1. SMTP 설정**

Admin UI → Settings → Mail Settings:
- SMTP 서버 정보 입력 (예: Mailpit 로컬 테스트 서버)

**2. 컬렉션 생성**

Admin UI → Collections → New Collection:
- Name: `orders`

**3. 레코드 생성**

```bash
curl -s -X POST http://localhost:8090/api/collections/orders/records \
  -H "Content-Type: application/json" \
  -d '{}'
```

이메일 수신함(또는 Mailpit)에서 알림 메일 확인.

SMTP 미설정 시 이메일 발송 실패 로그가 출력되지만 레코드는 정상 생성된다:

```bash
make logs
# [on_record_create_send_email] 이메일 발송 실패: ...
```

---

## 옵션 B: Go 확장 빌드

JS 훅 대신 Go로 PocketBase를 커스텀 빌드한다.
외부 Go 패키지가 필요하거나 성능이 중요한 경우에 사용한다.

### 빌드

`extend/main.go`를 수정한 후:

```bash
docker build \
  -f docker/Dockerfile.extend \
  --build-arg PB_VERSION=0.22.4 \
  -t pocketbase-custom .
```

### 실행 확인

```bash
docker run --rm -p 8090:8090 \
  -e PB_ADMIN_EMAIL=admin@example.com \
  -e PB_ADMIN_PASSWORD=changeme \
  pocketbase-custom
```

```bash
curl http://localhost:8090/api/health
# {"code":200,"message":"API is healthy."}
```

### 커스텀 로직 확인

레코드 생성 후 Docker 로그에서 커스텀 Go 훅 출력 확인:

```bash
docker logs <container_id>
# [hook] record created: posts / <record_id>
```
