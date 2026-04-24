// Delete a ticket (and its comments)
query "tickets/{ticket_id}" verb=DELETE {
  api_group = "HelpDesk"
  auth = "user"

  input {
    int ticket_id {
      table = "hd_ticket"
    }
  }

  stack {
    db.bulk.delete "hd_comment" {
      where = $db.hd_comment.ticket_id == $input.ticket_id
    } as $deleted_comments

    db.del "hd_ticket" {
      field_name = "id"
      field_value = $input.ticket_id
    }
  }

  response = {success: true}
}
