package main

import (
	"log"

	"github.com/pocketbase/pocketbase"
	"github.com/pocketbase/pocketbase/core"
)

func main() {
	app := pocketbase.New()

	app.OnRecordAfterCreate().Add(func(e *core.RecordCreateEvent) error {
		log.Printf("[hook] record created: %s / %s", e.Record.Collection().Name, e.Record.Id)
		
		return nil
	})

	if err := app.Start(); err != nil {
		log.Fatal(err)
	}
}