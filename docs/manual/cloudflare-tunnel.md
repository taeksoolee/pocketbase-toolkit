# Cloudflare Tunnel 매뉴얼

Cloudflare Tunnel은 서버 인바운드 포트(80/443)를 열지 않고, 서버 내부에서 Cloudflare로 아웃바운드 연결을 만들어 외부 HTTPS 요청을 전달하는 방식이다.

---

## 공식 문서 링크

- Cloudflare Tunnel 개요: https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/
- 시작 가이드: https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/get-started/
- Cloudflared 설정 참조: https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/configure-tunnels/
- Public Hostname 라우팅: https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/routing-to-tunnel/

---

## 기본 개념

- Tunnel: 원본 서버와 Cloudflare Edge를 연결하는 논리적 통로
- cloudflared: 서버 측 Tunnel 클라이언트 에이전트
- Public Hostname: 외부 도메인 요청을 내부 원본 주소로 라우팅하는 규칙

---

## 동작 흐름

1. 사용자가 HTTPS 도메인으로 접속
2. Cloudflare Edge가 요청 수신
3. cloudflared가 터널을 통해 요청 전달
4. 내부 원본 서비스(예: http://localhost:8080)로 프록시

핵심 장점:
- 인바운드 포트 개방 최소화
- 공인 IP가 없어도 외부 노출 가능

---

## 설정 순서

1. Cloudflare에 도메인 연결
2. Zero Trust에서 Tunnel 생성
3. Tunnel 토큰 발급
4. Public Hostname 생성
5. Public Hostname의 Service를 내부 원본 주소로 지정
6. 서버에서 cloudflared 실행

Docker 예시:

```yaml
services:
	cloudflared:
		image: cloudflare/cloudflared:latest
		command: tunnel --no-autoupdate run
		environment:
			- TUNNEL_TOKEN=YOUR_TOKEN
```

---

## 운영 점검

1. Zero Trust 대시보드에서 Tunnel 상태 확인
2. Public Hostname 라우팅 대상 확인
3. 원본 서비스 헬스체크 확인
4. 도메인으로 실제 접속 확인

---

## 자주 발생하는 문제

### 1) 도메인 접속 실패

원인:
- Tunnel 미연결
- Public Hostname 오타

대응:
- Tunnel 상태 Healthy 확인
- Hostname과 Service 주소 재검증

### 2) 502/5xx

원인:
- 원본 서비스 비정상
- Service 대상 포트/호스트 오설정

대응:
- 서버 내부에서 원본 서비스 직접 호출
- cloudflared 로그 확인

### 3) 토큰 갱신 후 연결 끊김

원인:
- 서버의 cloudflared가 이전 토큰 사용

대응:
- 새 토큰 반영 후 cloudflared 재시작

