// Update a ticket
query "tickets/{ticket_id}" verb=PATCH {
  api_group = "HelpDesk"
  auth = "user"

  input {
    int ticket_id {
      table = "hd_ticket"
    }
    text subject? filters=trim
    text description? filters=trim
    text status? filters=trim|lower
    text priority? filters=trim|lower
    int category_id?
    int assignee_id?
  }

  stack {
    var $updates {
      value = {updated_at: now}
    }

    conditional {
      if ($input.subject != null) {
        var.update $updates {
          value = $updates|set:"subject":$input.subject
        }
      }
    }
    conditional {
      if ($input.description != null) {
        var.update $updates {
          value = $updates|set:"description":$input.description
        }
      }
    }
    conditional {
      if ($input.status != null) {
        var.update $updates {
          value = $updates|set:"status":$input.status
        }
      }
    }
    conditional {
      if ($input.status == "resolved") {
        var.update $updates {
          value = $updates|set:"resolved_at":now
        }
      }
    }
    conditional {
      if ($input.priority != null) {
        var.update $updates {
          value = $updates|set:"priority":$input.priority
        }
      }
    }
    conditional {
      if ($input.category_id != null) {
        var.update $updates {
          value = $updates|set:"category_id":$input.category_id
        }
      }
    }
    conditional {
      if ($input.assignee_id != null) {
        var.update $updates {
          value = $updates|set:"assignee_id":$input.assignee_id
        }
      }
    }

    db.patch "hd_ticket" {
      field_name = "id"
      field_value = $input.ticket_id
      data = $updates
    } as $ticket
  }

  response = $ticket
}
