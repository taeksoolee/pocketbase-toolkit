# Make 매뉴얼 (GNU Make)

GNU Make는 반복되는 빌드/테스트/실행 명령을 타겟(target)으로 정의해 자동화하는 도구다.

---

## 공식 문서 링크

- GNU Make 공식 홈페이지: https://www.gnu.org/software/make/
- GNU Make 공식 매뉴얼: https://www.gnu.org/software/make/manual/make.html

---

## 설치 및 확인

macOS(Homebrew):

```bash
brew install make
```

Ubuntu/Debian:

```bash
sudo apt-get update
sudo apt-get install -y make
```

설치 확인:

```bash
make --version
```

---

## 기본 개념

- target: 실행 단위 이름
- prerequisite: 타겟 실행 전 필요한 파일/타겟
- recipe: 실제 실행할 셸 명령

기본 문법:

```make
target: prerequisite1 prerequisite2
	command1
	command2
```

주의:
- recipe 라인은 공백이 아닌 탭(tab)으로 시작해야 한다.

---

## 최소 예제

Makefile:

```make
.PHONY: build clean

build:
	echo "build step"

clean:
	rm -f dist/*
```

실행:

```bash
make build
make clean
```

---

## 자주 쓰는 패턴

변수 사용:

```make
CC = gcc
CFLAGS = -O2 -Wall

app: main.c
	$(CC) $(CFLAGS) -o app main.c
```

기본 타겟(default target):
- 파일 상단에 첫 번째로 선언한 타겟이 `make`만 입력했을 때 실행된다.

.PHONY 사용:
- 파일 이름과 충돌하지 않게 명령형 타겟에 선언한다.

```make
.PHONY: test
test:
	pytest -q
```

---

## 디버깅/점검

실행 명령 미리 보기:

```bash
make -n target
```

디버그 로그:

```bash
make -d target
```

변수 값 확인:

```bash
make -p | grep '^CC'
```

---

## 자주 겪는 문제

### 1) missing separator

원인:
- recipe 앞 들여쓰기에 탭 대신 스페이스 사용

해결:
- 해당 줄 시작을 탭으로 수정

### 2) No rule to make target

원인:
- 타겟명 오타 또는 prerequisite 누락

해결:
- 타겟명/의존관계 확인

### 3) 변경했는데 명령이 실행되지 않음

원인:
- 의존 파일 timestamp 기준으로 최신 상태로 판단

해결:
- `.PHONY` 적용 또는 `make -B target`로 강제 빌드