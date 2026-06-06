# Caddy 매뉴얼

Caddy는 Go 기반 오픈소스 웹 서버/리버스 프록시로, HTTPS 인증서 발급과 갱신(ACME)을 자동화해 운영 복잡도를 줄이는 데 강점이 있다.

---

## 공식 문서 링크

- Caddy 공식 사이트: https://caddyserver.com/
- Caddy 문서: https://caddyserver.com/docs/
- Caddyfile 문법: https://caddyserver.com/docs/caddyfile
- 자동 HTTPS: https://caddyserver.com/docs/automatic-https
- Reverse Proxy 지시어: https://caddyserver.com/docs/caddyfile/directives/reverse_proxy

---

## 기본 개념

- Caddyfile: 선언형 설정 파일
- Site Address: 도메인 또는 바인딩 주소
- reverse_proxy: 백엔드 서비스로 요청 전달
- Automatic HTTPS: TLS 인증서 자동 발급/갱신

핵심 포인트:
- 기본 설정만으로 HTTPS를 빠르게 적용할 수 있다.
- 인증서 갱신 자동화로 운영 실수를 줄일 수 있다.

---

## 동작 흐름

1. 클라이언트가 HTTPS 요청 전송
2. Caddy가 요청 수신 및 TLS 처리
3. 설정된 reverse_proxy 규칙으로 내부 백엔드 전달
4. 백엔드 응답을 Caddy가 클라이언트에 반환

요약:
- 외부는 Caddy와 통신하고, 내부 서비스는 사설 네트워크에 유지 가능
- TLS 종료를 Caddy에서 일원화 가능

---

## 장점

1. HTTPS 자동화
- ACME 기반 인증서 발급/갱신 자동 처리

2. 설정 단순성
- Caddyfile 문법이 짧고 읽기 쉬움

3. 기본 보안 설정
- 안전한 TLS 기본값 제공

4. 운영 효율
- 리버스 프록시, 정적 파일 제공, 헤더 처리 등을 단일 구성으로 통합 가능

5. 컨테이너 친화성
- Docker/Compose 환경에서 붙이기 쉬움

---

## 주의사항

1. 공인 네트워크 경로 필요
- 도메인 DNS와 서버 접근 경로(일반적으로 80/443)가 정상이어야 인증서 발급이 원활함

2. 인증서 저장소 보존
- 재배포 시 인증서 상태가 유지되도록 데이터 디렉터리 볼륨 관리 필요

3. 프록시 헤더 정책
- 백엔드에서 원본 IP/프로토콜 인식이 필요하면 관련 헤더 설정 점검 필요

---

## 최소 예시

Caddyfile:

```caddy
example.com {
	reverse_proxy 127.0.0.1:8080
}
```

의미:
- `example.com`으로 들어온 HTTPS 요청을 `127.0.0.1:8080` 백엔드로 전달

---

## 운영 점검 체크리스트

1. DNS 레코드가 올바른지 확인
2. 방화벽/보안그룹에서 필요한 포트 경로 확인
3. Caddy 로그에서 인증서 발급/갱신 상태 확인
4. 백엔드 헬스체크와 프록시 응답 지연 확인
5. 재시작/배포 후 인증서 저장소 보존 여부 확인

---

## 자주 발생하는 문제

### 1) 인증서 발급 실패

원인:
- DNS 미전파
- 도메인이 서버를 가리키지 않음
- HTTP-01/TLS-ALPN 챌린지 경로 차단

대응:
- 도메인 해석 결과와 서버 도달성 확인
- 80/443 경로 차단 여부 확인
- Caddy 로그에서 ACME 에러 코드 확인

### 2) 502 Bad Gateway

원인:
- 백엔드 미기동
- reverse_proxy 대상 주소/포트 오설정

대응:
- 서버 내부에서 백엔드 직접 호출로 상태 확인
- Caddyfile의 업스트림 주소 재검증

### 3) 리다이렉트/헤더 이상

원인:
- 백엔드의 URL 스킴 인식 불일치
- 프록시 헤더 누락/중복

대응:
- 백엔드의 프록시 신뢰 설정 점검
- 요청/응답 헤더 캡처로 실제 전달값 확인

---

## 언제 적합한가

- 빠르게 HTTPS를 붙여야 할 때
- 인증서 운영 자동화를 선호할 때
- 단순한 리버스 프록시 구성을 유지하고 싶을 때

## 언제 다른 선택이 나을 수 있는가

- 외부 포트를 열기 어려운 네트워크 정책인 경우
- 별도의 글로벌 엣지 네트워크 정책/WAF를 우선 적용해야 하는 경우
