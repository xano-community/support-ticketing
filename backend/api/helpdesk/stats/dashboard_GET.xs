// Dashboard stats: counts by status, priority, overdue
query "stats/dashboard" verb=GET {
  api_group = "HelpDesk"
  auth = "user"

  input {}

  stack {
    db.query "hd_ticket" {
      where = $db.hd_ticket.status == "open"
      return = {type: "count"}
    } as $open_count

    db.query "hd_ticket" {
      where = $db.hd_ticket.status == "in_progress"
      return = {type: "count"}
    } as $in_progress_count

    db.query "hd_ticket" {
      where = $db.hd_ticket.status == "resolved"
      return = {type: "count"}
    } as $resolved_count

    db.query "hd_ticket" {
      where = $db.hd_ticket.priority == "urgent" && $db.hd_ticket.status != "closed" && $db.hd_ticket.status != "resolved"
      return = {type: "count"}
    } as $urgent_count

    db.query "hd_ticket" {
      where = $db.hd_ticket.sla_due_at < now && $db.hd_ticket.status != "resolved" && $db.hd_ticket.status != "closed"
      return = {type: "count"}
    } as $overdue_count
  }

  response = {
    open: $open_count,
    in_progress: $in_progress_count,
    resolved: $resolved_count,
    urgent_active: $urgent_count,
    overdue: $overdue_count
  }
}
