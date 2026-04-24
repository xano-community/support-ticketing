// Add a comment to a ticket
query "tickets/{ticket_id}/comments" verb=POST {
  api_group = "HelpDesk"
  auth = "user"

  input {
    int ticket_id {
      table = "hd_ticket"
    }
    text body filters=trim
    bool is_internal?=false
  }

  stack {
    db.add "hd_comment" {
      data = {
        ticket_id  : $input.ticket_id,
        author_id  : $auth.id,
        body       : $input.body,
        is_internal: $input.is_internal
      }
    } as $comment

    db.edit "hd_ticket" {
      field_name = "id"
      field_value = $input.ticket_id
      data = {updated_at: now}
    }
  }

  response = $comment
}
