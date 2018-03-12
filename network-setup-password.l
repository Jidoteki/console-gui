# network-setup-password.l

(setq *Admin_user "tcroot")

### Public

[de ask-menu-password ()
  (colour "clear")
  (prinl)
  (prinl (align 16 "Password for (")
         (colour "green") *Admin_user (colour) "):" )
  (tab (list (+ 2 16 (length *Admin_user))) (pack (need (+ 16 (length *Admin_user)) "-")))
  (colour "cursor")
  (prin (align 2)
        "Do you want to "
        (colour "red")
        (colour "bold")
        "change"
        (colour)
        " the "
        (colour "green")
        *Admin_user
        (colour)
        " password ? (y/N) "
        (colour)
        "[default: N] " )

  (colour)
  (if (= "y" (lowc (key *Refresh_time)))
      (prog
        (prinl "^J")
        (call '/usr/bin/passwd *Admin_user) )
      (prinl) )

  (colour "nocursor")
  (print-wait-any-key) ]

[de print-menu-password (Num)
  (print-menu-option NIL Num "Change password") ]
