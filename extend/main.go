package main

import (
	"log"

	"github.com/pocketbase/pocketbase"
	"github.com/pocketbase/pocketbase/core"
)

func main() {
	app := pocketbase.New()

	// 예시: 레코드 생성 후 커스텀 Go 로직 실행
	// JS 훅으로 처리하기 어려운 복잡한 비즈니스 로직이나
	// 외부 Go 패키지가 필요한 경우 이곳에 작성한다.
	app.OnRecordAfterCreateSuccess().BindFunc(func(e *core.RecordEvent) error {
		log.Printf("[hook] record created: %s / %s", e.Record.Collection().Name, e.Record.Id)
		return e.Next()
	})

	if err := app.Start(); err != nil {
		log.Fatal(err)
	}
}
