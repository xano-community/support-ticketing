// List comments on a ticket
query "tickets/{ticket_id}/comments" verb=GET {
  api_group = "HelpDesk"
  auth = "user"

  input {
    int ticket_id
  }

  stack {
    db.query "hd_comment" {
      where = $db.hd_comment.ticket_id == $input.ticket_id
      sort = {created_at: "asc"}
    } as $comments

    var $enriched { value = [] }

    foreach ($comments) {
      each as $c {
        db.get "user" {
          field_name = "id"
          field_value = $c.author_id
          output = ["id", "name"]
        } as $author

        var.update $enriched {
          value = $enriched|push:($c|set:"author":$author)
        }
      }
    }
  }

  response = $enriched
}
