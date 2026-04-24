// Create a new support ticket
query "tickets" verb=POST {
  api_group = "Ticketing"
  auth = "user"

  input {
    text subject filters=trim
    text description? filters=trim
    text priority? filters=trim|lower
    int category_id?
    int assignee_id?
  }

  stack {
    db.add "ticket" {
      data = {
        subject      : $input.subject,
        description  : $input.description,
        priority     : ($input.priority == null ? "medium" : $input.priority),
        category_id  : $input.category_id,
        assignee_id  : $input.assignee_id,
        requester_id : $auth.id,
        status       : "open",
        sla_due_at   : now|add_secs_to_timestamp:259200
      }
    } as $ticket
  }

  response = $ticket
}
