// Create a new ticket category
query "categories" verb=POST {
  api_group = "HelpDesk"
  auth = "user"

  input {
    text name filters=trim
    text description? filters=trim
  }

  stack {
    db.add "hd_category" {
      data = {
        name       : $input.name,
        description: $input.description
      }
    } as $category
  }

  response = $category
}
