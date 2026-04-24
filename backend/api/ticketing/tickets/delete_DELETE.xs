// Delete a ticket (and its comments)
query "tickets/{ticket_id}" verb=DELETE {
  api_group = "Ticketing"
  auth = "user"

  input {
    int ticket_id {
      table = "ticket"
    }
  }

  stack {
    db.bulk.delete "ticket_comment" {
      where = $db.ticket_comment.ticket_id == $input.ticket_id
    } as $deleted_comments

    db.del "ticket" {
      field_name = "id"
      field_value = $input.ticket_id
    }
  }

  response = {success: true}
}
