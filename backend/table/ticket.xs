table "ticket" {
  auth = false

  schema {
    int id
    timestamp created_at?=now
    timestamp updated_at?
    text subject filters=trim
    text description?
    enum status?="open" {
      values = ["open", "in_progress", "pending", "resolved", "closed"]
    }
    enum priority?="medium" {
      values = ["low", "medium", "high", "urgent"]
    }
    int category_id? {
      table = "ticket_category"
    }
    int requester_id {
      table = "user"
    }
    int assignee_id? {
      table = "user"
    }
    timestamp sla_due_at?
    timestamp resolved_at?
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "status"}]}
    {type: "btree", field: [{name: "priority"}]}
    {type: "btree", field: [{name: "requester_id"}]}
    {type: "btree", field: [{name: "assignee_id"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
  ]
}
