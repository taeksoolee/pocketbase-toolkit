package main

import (
	"log"

	"github.com/pocketbase/pocketbase"
	"github.com/pocketbase/pocketbase/core"
)

func main() {
	app := pocketbase.New()

	app.OnRecordCreateExecute().BindFunc(func(e *core.RecordCreateEvent) error {
		if err := e.Next(); err != nil {
			return err // 생성 중 에러가 나면 즉시 중단 및 롤백
		}

		log.Printf("[hook] record created: %s / %s", e.Collection.Name, e.Record.Id)

		return nil
	})

	if err := app.Start(); err != nil {
		log.Fatal(err)
	}
}