# PocketBase 매뉴얼

PocketBase는 SQLite 기반의 오픈소스 백엔드로, 인증/Auth, DB, 파일 스토리지, Admin UI, Realtime API를 단일 바이너리로 제공한다.

---

## 공식 문서 링크

- PocketBase 공식 홈페이지: https://pocketbase.io
- PocketBase 공식 문서: https://pocketbase.io/docs/
- PocketBase GitHub: https://github.com/pocketbase/pocketbase
- 릴리즈 노트: https://github.com/pocketbase/pocketbase/releases

---

## 빠른 시작

macOS/Linux 바이너리 실행 예시:

```bash
# 다운로드 후 실행 권한 부여
chmod +x pocketbase

# 서버 실행
./pocketbase serve
```

기본 접속:
- Admin UI: http://127.0.0.1:8090/_/
- Health API: http://127.0.0.1:8090/api/health

참고:
- `/` 루트는 앱 라우트가 없으면 404가 나올 수 있다.
- Admin UI는 `/_/` 경로다.

---

## 핵심 개념

- Collection: 데이터 스키마 단위
- Record: 컬렉션의 개별 데이터
- Auth collection: 사용자 인증용 컬렉션
- Rule: 목록/조회/생성/수정/삭제 접근 제어 규칙
- Realtime: 레코드 변경 이벤트 구독

---

## 자주 쓰는 CLI

서버 실행:

```bash
./pocketbase serve
```

다른 포트로 실행:

```bash
./pocketbase serve --http=0.0.0.0:8090
```

마이그레이션 생성/실행은 버전별로 명령이 다를 수 있으므로 공식 문서 기준으로 사용한다.

---

## 운영 기본 원칙

- 업그레이드 전 백업
- 백업 파일의 주기적 복원 테스트
- Admin 계정에 강한 비밀번호 + 2FA 적용
- 공개 서비스는 리버스 프록시/HTTPS 뒤에서 운영
- Rule을 기본 deny 관점으로 설계

---

## 트러블슈팅

### 1) 404 Not Found

원인:
- `/` 경로 접근 (앱 라우트 미정의)

해결:
- `/_/` 또는 API 경로로 접근

### 2) 포트 충돌

증상:
- bind: address already in use

해결:

```bash
lsof -nP -iTCP:8090 -sTCP:LISTEN
```

충돌 프로세스를 중지하거나 다른 포트로 실행.

### 3) 업그레이드 후 오류

원인:
- 버전 간 호환 이슈 또는 마이그레이션 누락

해결:
- 릴리즈 노트 확인 후 백업본으로 복원하고 단계적으로 업그레이드