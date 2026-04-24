table "hd_comment" {
  auth = false

  schema {
    int id
    timestamp created_at?=now
    int ticket_id {
      table = "hd_ticket"
    }
    int author_id {
      table = "user"
    }
    text body filters=trim
    bool is_internal?=false
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "ticket_id"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
  ]
}
