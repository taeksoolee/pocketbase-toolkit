/// <reference path="../pb_data/types.d.ts" />

// 예시: 레코드 생성 후 이메일 발송
// 특정 컬렉션(예: "orders")에 레코드가 생성되면 관리자에게 알림 이메일을 보낸다.
//
// 실제 사용 시:
//   1. "orders"를 대상 컬렉션 이름으로 변경
//   2. ADMIN_EMAIL을 실제 관리자 이메일로 변경
//   3. PocketBase Admin UI → Settings → Mail Settings에서 SMTP 설정 필요

const ADMIN_EMAIL = "admin@example.com"

onRecordAfterCreateSuccess((e) => {
  const record = e.record
  const app = e.app

  try {
    const message = new MailerMessage()
    message.setFrom({ address: app.settings().meta.senderAddress })
    message.addTo({ address: ADMIN_EMAIL })
    message.setSubject(`[알림] 새 레코드 생성: ${record.collection().name}`)
    message.setHTML(`
      <p>새 레코드가 생성되었습니다.</p>
      <ul>
        <li><strong>컬렉션:</strong> ${record.collection().name}</li>
        <li><strong>ID:</strong> ${record.id}</li>
        <li><strong>생성 시각:</strong> ${record.created}</li>
      </ul>
    `)

    app.mailer().send(message)
  } catch (err) {
    // 이메일 발송 실패는 레코드 생성에 영향을 주지 않도록 처리
    console.error("[on_record_create_send_email] 이메일 발송 실패:", err)
  }

  e.next()
}, "orders")
