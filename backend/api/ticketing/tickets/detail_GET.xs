// Get a ticket by ID with category, requester, and assignee info
query "tickets/{ticket_id}" verb=GET {
  api_group = "Ticketing"
  auth = "user"

  input {
    int ticket_id
  }

  stack {
    db.get "ticket" {
      field_name = "id"
      field_value = $input.ticket_id
    } as $ticket

    precondition ($ticket != null) {
      error_type = "notfound"
      error = "Ticket not found"
    }

    db.get "ticket_category" {
      field_name = "id"
      field_value = $ticket.category_id
    } as $category

    db.get "user" {
      field_name = "id"
      field_value = $ticket.requester_id
      output = ["id", "name", "email"]
    } as $requester

    db.get "user" {
      field_name = "id"
      field_value = $ticket.assignee_id
      output = ["id", "name", "email"]
    } as $assignee

    var $result {
      value = $ticket|set:"category":$category|set:"requester":$requester|set:"assignee":$assignee
    }
  }

  response = $result
}
