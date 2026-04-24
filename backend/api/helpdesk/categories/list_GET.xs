// List ticket categories
query "categories" verb=GET {
  api_group = "HelpDesk"

  input {}

  stack {
    db.query "hd_category" {
      sort = {name: "asc"}
    } as $categories
  }

  response = $categories
}
