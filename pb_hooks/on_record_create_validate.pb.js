/// <reference path="../pb_data/types.d.ts" />

// 예시: 레코드 생성 전 유효성 검사
// 특정 컬렉션(예: "posts")의 레코드 생성 전 title 필드 길이를 검사한다.
//
// 실제 사용 시 "posts"를 대상 컬렉션 이름으로 변경하세요.

onRecordCreateRequest((e) => {
  const title = e.record.get("title")

  if (!title || title.trim().length < 5) {
    throw new BadRequestError("title은 최소 5자 이상이어야 합니다.")
  }

  if (title.length > 200) {
    throw new BadRequestError("title은 200자를 초과할 수 없습니다.")
  }

  e.next()
}, "posts")
