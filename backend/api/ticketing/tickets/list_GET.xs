// List tickets with filtering and pagination
query "tickets" verb=GET {
  api_group = "Ticketing"
  auth = "user"

  input {
    text status? filters=trim|lower
    text priority? filters=trim|lower
    int category_id?
    int assignee_id?
    int page?=1 filters=min:1
    int per_page?=20 filters=min:1|max:100
  }

  stack {
    db.query "ticket" {
      where = $db.ticket.status ==? $input.status && $db.ticket.priority ==? $input.priority && $db.ticket.category_id ==? $input.category_id && $db.ticket.assignee_id ==? $input.assignee_id
      sort = {created_at: "desc"}
      return = {
        type: "list",
        paging: {page: $input.page, per_page: $input.per_page, totals: true}
      }
    } as $tickets
  }

  response = $tickets
}
