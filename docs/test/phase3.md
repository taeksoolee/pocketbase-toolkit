# Phase 3 테스트 — 백업, 복원, 업그레이드

## 전제 조건

`make up`으로 PocketBase가 실행 중이어야 한다.

```bash
make up
docker compose -f compose/docker-compose.yml ps  # pocketbase: healthy 확인
```

---

## 백업 테스트

### 수동 백업

```bash
make backup
```

예상 출력:
```
[backup] 인증 중...
[backup] 백업 생성 중...
[backup] 백업 목록 조회 중...
[backup] 다운로드 중: pb_backup_2024-01-01_02-00-00.zip
[backup] 저장 완료: ./backups/backup_20240101_020000.zip
[backup] 7일 이전 백업 정리 완료
```

### 검증

```bash
ls -lh backups/
# backup_YYYYMMDD_HHMMSS.zip 파일 존재 확인
```

PocketBase Admin UI → Settings → Backups 메뉴에서도 백업 목록 확인 가능.

---

## 복원 테스트

### 테스트 데이터 준비

Admin UI에서 컬렉션을 만들거나 레코드를 추가해서 복원 전후 비교 기준 데이터를 만든다.

### 백업 생성

```bash
make backup
```

### 데이터 변경

Admin UI에서 레코드를 삭제하거나 수정한다.

### 복원 실행

```bash
make restore
```

출력 예시:
```
[restore] 사용 가능한 백업 목록:

  1) backup_20240101_030000.zip (512K)
  2) backup_20240101_020000.zip (510K)

[restore] 복원할 번호 입력: 1
[restore] 선택된 파일: backup_20240101_030000.zip
[restore] 계속 진행하면 현재 데이터가 덮어씁니다. 진행하시겠습니까? (y/N): y
[restore] 인증 중...
[restore] 서버에 백업 파일 업로드 중...
[restore] 복원 실행 중...
[restore] 복원 완료. 서버가 재시작됩니다.
```

### 검증

서버 재시작 후 Admin UI 접속 → 백업 시점의 데이터로 복원되었는지 확인.

---

## 업그레이드 테스트

### 현재 버전 확인

```bash
grep PB_VERSION .env
# PB_VERSION=0.22.4
```

### 업그레이드 실행

```bash
make upgrade VERSION=0.22.5
```

예상 출력:
```
[upgrade] 0.22.4 → 0.22.5 업그레이드 시작
[upgrade] 1/4 업그레이드 전 백업 실행...
...
[upgrade] 2/4 PB_VERSION 변경: 0.22.4 → 0.22.5
[upgrade] 3/4 컨테이너 재빌드 및 재시작...
[upgrade] 4/4 헬스체크 대기 중...
[upgrade] 업그레이드 완료: 0.22.5
```

### 검증

```bash
grep PB_VERSION .env           # 0.22.5 확인
docker compose -f compose/docker-compose.yml ps  # healthy 확인
curl http://localhost:8090/api/health
```

### 롤백 테스트 (존재하지 않는 버전으로 시도)

```bash
make upgrade VERSION=99.99.99
# 헬스체크 실패 → 자동 롤백 → 이전 버전으로 복구 확인
```

---

## 자동 백업 (프로덕션)

`make prod-up` 실행 시 ofelia 컨테이너가 함께 기동되며, 매일 새벽 2시에 자동 백업이 실행된다.

```bash
# ofelia 로그에서 스케줄 등록 확인
docker compose -f compose/docker-compose.yml -f compose/docker-compose.prod.yml logs ofelia
```
