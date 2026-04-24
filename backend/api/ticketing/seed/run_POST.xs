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
