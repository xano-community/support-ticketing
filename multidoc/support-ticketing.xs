workspace templates {
  acceptance = {ai_terms: false}
  preferences = {
    internal_docs    : false
    track_performance: true
    sql_names        : false
    sql_columns      : true
  }
}
---
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
---
table "ticket_comment" {
  auth = false

  schema {
    int id
    timestamp created_at?=now
    int ticket_id {
      table = "ticket"
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
---
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
---
table user {
  auth = true

  schema {
    int id
    timestamp created_at?=now {
      visibility = "private"
    }
  
    text name filters=trim
    email? email filters=trim|lower
    password? password filters=min:8|minAlpha:1|minDigit:1 {
      visibility = "internal"
    }
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
    {type: "btree|unique", field: [{name: "email", op: "asc"}]}
  ]

}
---
api_group EnterpriseAuth {
  description = "Shared authentication for Support Ticketing, AssetVault, and ProcureFlow"
  tags = ["auth", "shared"]
}
---
// Login and retrieve an authentication token
query "login" verb=POST {
  api_group = "EnterpriseAuth"

  input {
    email email filters=trim|lower
    text password
  }

  stack {
    db.get "user" {
      field_name = "email"
      field_value = $input.email
      output = ["id", "created_at", "name", "email", "password"]
    } as $user

    precondition ($user != null) {
      error_type = "accessdenied"
      error = "Invalid credentials"
    }

    security.check_password {
      text_password = $input.password
      hash_password = $user.password
    } as $pass_result

    precondition ($pass_result) {
      error_type = "accessdenied"
      error = "Invalid credentials"
    }

    security.create_auth_token {
      table = "user"
      extras = {}
      expiration = 86400
      id = $user.id
    } as $authToken
  }

  response = {
    authToken: $authToken,
    user: {id: $user.id, name: $user.name, email: $user.email}
  }
}
---
// Get the currently authenticated user
query "me" verb=GET {
  api_group = "EnterpriseAuth"
  auth = "user"

  input {}

  stack {
    db.get "user" {
      field_name = "id"
      field_value = $auth.id
      output = ["id", "created_at", "name", "email"]
    } as $user
  }

  response = $user
}
---
// Create a new account and retrieve an authentication token
query "signup" verb=POST {
  api_group = "EnterpriseAuth"

  input {
    text name filters=trim
    email email filters=trim|lower
    text password
  }

  stack {
    db.get "user" {
      field_name = "email"
      field_value = $input.email
    } as $existing

    precondition ($existing == null) {
      error_type = "inputerror"
      error = "Email already registered"
    }

    db.add "user" {
      data = {
        name    : $input.name,
        email   : $input.email,
        password: $input.password
      }
    } as $user

    security.create_auth_token {
      table = "user"
      extras = {}
      expiration = 86400
      id = $user.id
    } as $authToken
  }

  response = {
    authToken: $authToken,
    user: {id: $user.id, name: $user.name, email: $user.email}
  }
}
---
// List users (for selector dropdowns across apps)
query "users" verb=GET {
  api_group = "EnterpriseAuth"
  auth = "user"

  input {}

  stack {
    db.query "user" {
      sort = {name: "asc"}
      return = {type: "list"}
    } as $users

    var $sanitized { value = [] }

    foreach ($users) {
      each as $u {
        var.update $sanitized {
          value = $sanitized|push:{id: $u.id, name: $u.name, email: $u.email}
        }
      }
    }
  }

  response = $sanitized
}
---
// Create a new ticket category
query "categories" verb=POST {
  api_group = "Ticketing"
  auth = "user"

  input {
    text name filters=trim
    text description? filters=trim
  }

  stack {
    db.add "ticket_category" {
      data = {
        name       : $input.name,
        description: $input.description
      }
    } as $category
  }

  response = $category
}
---
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
---
// Seed Ticketing with realistic demo data. Idempotent: skips records that already exist.
query "seed" verb=POST {
  api_group = "Ticketing"

  input {}

  stack {
    db.query "ticket" {
      return = {type: "count"}
    } as $existing_tickets

    precondition ($existing_tickets == 0) {
      error_type = "inputerror"
      error = "Ticketing data already seeded. Truncate ticket to reseed."
    }

    var $seed_users {
      value = [
        {name: "Alice Johnson",   email: "alice.johnson@acme.enterprise"},
        {name: "Bob Martinez",    email: "bob.martinez@acme.enterprise"},
        {name: "Carol Nguyen",    email: "carol.nguyen@acme.enterprise"},
        {name: "David Okonkwo",   email: "david.okonkwo@acme.enterprise"},
        {name: "Emma Patel",      email: "emma.patel@acme.enterprise"},
        {name: "Frank Rivera",    email: "frank.rivera@acme.enterprise"},
        {name: "Grace Sullivan",  email: "grace.sullivan@acme.enterprise"},
        {name: "Henry Tanaka",    email: "henry.tanaka@acme.enterprise"}
      ]
    }

    foreach ($seed_users) {
      each as $seed_user {
        db.get "user" {
          field_name = "email"
          field_value = $seed_user.email
        } as $existing

        conditional {
          if ($existing == null) {
            db.add "user" {
              data = {
                name    : $seed_user.name,
                email   : $seed_user.email,
                password: "DemoPass1"
              }
            }
          }
        }
      }
    }

    var $category_seeds {
      value = [
        {name: "Hardware",          description: "Laptops, monitors, peripherals"},
        {name: "Software",          description: "Application installs, licenses, bugs"},
        {name: "Network",           description: "VPN, Wi-Fi, connectivity"},
        {name: "Access",            description: "Account access, permissions, SSO"},
        {name: "Email",             description: "Mailbox, aliases, spam"},
        {name: "Security",          description: "Phishing, password, endpoint alerts"}
      ]
    }

    foreach ($category_seeds) {
      each as $cat_seed {
        db.get "ticket_category" {
          field_name = "name"
          field_value = $cat_seed.name
        } as $existing_cat

        conditional {
          if ($existing_cat == null) {
            db.add "ticket_category" {
              data = {
                name       : $cat_seed.name,
                description: $cat_seed.description
              }
            }
          }
        }
      }
    }

    var $ticket_seeds {
      value = [
        {subject: "Laptop will not power on after update",                 priority: "urgent",  status: "open",        cat_name: "Hardware", req_email: "alice.johnson@acme.enterprise",  asg_email: "bob.martinez@acme.enterprise"},
        {subject: "Need admin rights to install design software",          priority: "medium",  status: "in_progress", cat_name: "Access",   req_email: "carol.nguyen@acme.enterprise",   asg_email: "bob.martinez@acme.enterprise"},
        {subject: "Outlook crashes when opening attachments",              priority: "high",    status: "open",        cat_name: "Email",    req_email: "david.okonkwo@acme.enterprise",  asg_email: "bob.martinez@acme.enterprise"},
        {subject: "VPN disconnects every 10 minutes",                      priority: "high",    status: "in_progress", cat_name: "Network",  req_email: "emma.patel@acme.enterprise",     asg_email: "frank.rivera@acme.enterprise"},
        {subject: "Request new 27-inch monitor for home office",           priority: "low",     status: "pending",     cat_name: "Hardware", req_email: "frank.rivera@acme.enterprise",   asg_email: "bob.martinez@acme.enterprise"},
        {subject: "Suspicious phishing email from vendor-portal.co",       priority: "urgent",  status: "in_progress", cat_name: "Security", req_email: "grace.sullivan@acme.enterprise", asg_email: "frank.rivera@acme.enterprise"},
        {subject: "Slack app stuck on loading screen",                     priority: "medium",  status: "resolved",    cat_name: "Software", req_email: "henry.tanaka@acme.enterprise",   asg_email: "frank.rivera@acme.enterprise"},
        {subject: "Printer on 3rd floor offline",                          priority: "medium",  status: "open",        cat_name: "Hardware", req_email: "alice.johnson@acme.enterprise",  asg_email: "bob.martinez@acme.enterprise"},
        {subject: "Cannot access shared finance drive",                    priority: "high",    status: "pending",     cat_name: "Access",   req_email: "carol.nguyen@acme.enterprise",   asg_email: "frank.rivera@acme.enterprise"},
        {subject: "Password reset link not arriving",                      priority: "medium",  status: "resolved",    cat_name: "Access",   req_email: "david.okonkwo@acme.enterprise",  asg_email: "bob.martinez@acme.enterprise"},
        {subject: "Zoom microphone not detected on conference room PC",    priority: "high",    status: "in_progress", cat_name: "Software", req_email: "emma.patel@acme.enterprise",     asg_email: "frank.rivera@acme.enterprise"},
        {subject: "Request MacBook Pro for new hire starting Monday",      priority: "medium",  status: "open",        cat_name: "Hardware", req_email: "frank.rivera@acme.enterprise",   asg_email: "bob.martinez@acme.enterprise"},
        {subject: "SSO redirect loop on Salesforce",                       priority: "urgent",  status: "open",        cat_name: "Access",   req_email: "grace.sullivan@acme.enterprise", asg_email: "frank.rivera@acme.enterprise"},
        {subject: "Outlook calendar invitations not syncing",              priority: "medium",  status: "closed",      cat_name: "Email",    req_email: "henry.tanaka@acme.enterprise",   asg_email: "bob.martinez@acme.enterprise"},
        {subject: "Wireless connection drops in conference room B",        priority: "low",     status: "open",        cat_name: "Network",  req_email: "alice.johnson@acme.enterprise",  asg_email: "frank.rivera@acme.enterprise"},
        {subject: "Two-factor auth prompts repeatedly",                    priority: "high",    status: "in_progress", cat_name: "Security", req_email: "carol.nguyen@acme.enterprise",   asg_email: "bob.martinez@acme.enterprise"},
        {subject: "Database connection errors in accounting app",          priority: "urgent",  status: "open",        cat_name: "Software", req_email: "david.okonkwo@acme.enterprise",  asg_email: "frank.rivera@acme.enterprise"},
        {subject: "New employee onboarding - setup accounts",              priority: "medium",  status: "pending",     cat_name: "Access",   req_email: "emma.patel@acme.enterprise",     asg_email: "bob.martinez@acme.enterprise"},
        {subject: "External hard drive not recognized",                    priority: "low",     status: "resolved",    cat_name: "Hardware", req_email: "frank.rivera@acme.enterprise",   asg_email: "frank.rivera@acme.enterprise"},
        {subject: "Email forwarding rule needs to be disabled",            priority: "low",     status: "closed",      cat_name: "Email",    req_email: "grace.sullivan@acme.enterprise", asg_email: "bob.martinez@acme.enterprise"}
      ]
    }

    var $ticket_count { value = 0 }

    foreach ($ticket_seeds) {
      each as $t {
        db.get "user" {
          field_name = "email"
          field_value = $t.req_email
        } as $requester

        db.get "user" {
          field_name = "email"
          field_value = $t.asg_email
        } as $assignee

        db.get "ticket_category" {
          field_name = "name"
          field_value = $t.cat_name
        } as $category

        db.add "ticket" {
          data = {
            subject      : $t.subject,
            description  : ("Reported by " ~ $requester.name ~ ". Please investigate and resolve per SLA policy."),
            status       : $t.status,
            priority     : $t.priority,
            category_id  : $category.id,
            requester_id : $requester.id,
            assignee_id  : $assignee.id,
            sla_due_at   : now|add_secs_to_timestamp:259200
          }
        } as $ticket

        conditional {
          if ($t.status == "resolved" || $t.status == "closed") {
            db.edit "ticket" {
              field_name = "id"
              field_value = $ticket.id
              data = {resolved_at: now}
            }
          }
        }

        db.add "ticket_comment" {
          data = {
            ticket_id  : $ticket.id,
            author_id  : $assignee.id,
            body       : "Acknowledged. Working on this now.",
            is_internal: false
          }
        }

        conditional {
          if ($t.status != "open") {
            db.add "ticket_comment" {
              data = {
                ticket_id  : $ticket.id,
                author_id  : $requester.id,
                body       : "Thanks, please keep me posted on progress.",
                is_internal: false
              }
            }
          }
        }

        var.update $ticket_count {
          value = $ticket_count + 1
        }
      }
    }
  }

  response = {
    success: true,
    tickets_seeded: $ticket_count
  }
}
---
// Dashboard stats: counts by status, priority, overdue
query "stats/dashboard" verb=GET {
  api_group = "Ticketing"
  auth = "user"

  input {}

  stack {
    db.query "ticket" {
      where = $db.ticket.status == "open"
      return = {type: "count"}
    } as $open_count

    db.query "ticket" {
      where = $db.ticket.status == "in_progress"
      return = {type: "count"}
    } as $in_progress_count

    db.query "ticket" {
      where = $db.ticket.status == "resolved"
      return = {type: "count"}
    } as $resolved_count

    db.query "ticket" {
      where = $db.ticket.priority == "urgent" && $db.ticket.status != "closed" && $db.ticket.status != "resolved"
      return = {type: "count"}
    } as $urgent_count

    db.query "ticket" {
      where = $db.ticket.sla_due_at < now && $db.ticket.status != "resolved" && $db.ticket.status != "closed"
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
---
api_group Ticketing {
  description = "Support Ticketing - IT ticketing system"
  tags = ["ticketing", "tickets", "support"]
}
---
// Add a comment to a ticket
query "tickets/{ticket_id}/comments" verb=POST {
  api_group = "Ticketing"
  auth = "user"

  input {
    int ticket_id {
      table = "ticket"
    }
    text body filters=trim
    bool is_internal?=false
  }

  stack {
    db.add "ticket_comment" {
      data = {
        ticket_id  : $input.ticket_id,
        author_id  : $auth.id,
        body       : $input.body,
        is_internal: $input.is_internal
      }
    } as $comment

    db.edit "ticket" {
      field_name = "id"
      field_value = $input.ticket_id
      data = {updated_at: now}
    }
  }

  response = $comment
}
---
// List comments on a ticket
query "tickets/{ticket_id}/comments" verb=GET {
  api_group = "Ticketing"
  auth = "user"

  input {
    int ticket_id
  }

  stack {
    db.query "ticket_comment" {
      where = $db.ticket_comment.ticket_id == $input.ticket_id
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
---
// Create a new support ticket
query "tickets" verb=POST {
  api_group = "Ticketing"
  auth = "user"

  input {
    text subject filters=trim
    text description? filters=trim
    text priority? filters=trim|lower
    int category_id?
    int assignee_id?
  }

  stack {
    db.add "ticket" {
      data = {
        subject      : $input.subject,
        description  : $input.description,
        priority     : ($input.priority == null ? "medium" : $input.priority),
        category_id  : $input.category_id,
        assignee_id  : $input.assignee_id,
        requester_id : $auth.id,
        status       : "open",
        sla_due_at   : now|add_secs_to_timestamp:259200
      }
    } as $ticket
  }

  response = $ticket
}
---
// Delete a ticket (and its comments)
query "tickets/{ticket_id}" verb=DELETE {
  api_group = "Ticketing"
  auth = "user"

  input {
    int ticket_id {
      table = "ticket"
    }
  }

  stack {
    db.bulk.delete "ticket_comment" {
      where = $db.ticket_comment.ticket_id == $input.ticket_id
    } as $deleted_comments

    db.del "ticket" {
      field_name = "id"
      field_value = $input.ticket_id
    }
  }

  response = {success: true}
}
---
// Get a ticket by ID with category, requester, and assignee info
query "tickets/{ticket_id}" verb=GET {
  api_group = "Ticketing"
  auth = "user"

  input {
    int ticket_id
  }

  stack {
    db.get "ticket" {
      field_name = "id"
      field_value = $input.ticket_id
    } as $ticket

    precondition ($ticket != null) {
      error_type = "notfound"
      error = "Ticket not found"
    }

    db.get "ticket_category" {
      field_name = "id"
      field_value = $ticket.category_id
    } as $category

    db.get "user" {
      field_name = "id"
      field_value = $ticket.requester_id
      output = ["id", "name", "email"]
    } as $requester

    db.get "user" {
      field_name = "id"
      field_value = $ticket.assignee_id
      output = ["id", "name", "email"]
    } as $assignee

    var $result {
      value = $ticket|set:"category":$category|set:"requester":$requester|set:"assignee":$assignee
    }
  }

  response = $result
}
---
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
---
// Update a ticket
query "tickets/{ticket_id}" verb=PATCH {
  api_group = "Ticketing"
  auth = "user"

  input {
    int ticket_id {
      table = "ticket"
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

    db.patch "ticket" {
      field_name = "id"
      field_value = $input.ticket_id
      data = $updates
    } as $ticket
  }

  response = $ticket
}
