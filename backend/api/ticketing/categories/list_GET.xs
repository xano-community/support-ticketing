// List ticket categories
query "categories" verb=GET {
  api_group = "Ticketing"

  input {}

  stack {
    db.query "ticket_category" {
      sort = {name: "asc"}
    } as $categories
  }

  response = $categories
}
