table "ticket_category" {
  auth = false

  schema {
    int id
    timestamp created_at?=now
    text name filters=trim
    text description?
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree|unique", field: [{name: "name"}]}
  ]
}
