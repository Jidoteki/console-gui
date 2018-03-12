#!/usr/bin/env pil

[de APP_INFO
  ("name"      "network-setup.l")
  ("version"   "4.4.0")
  ("summary"   "Read and configure network settings (IPv4/IPv6) - Trial version")
  ("source"    "https://github.com/on-prem/console-gui")
  ("author"    "Alexander Williams")
  ("license"   "MPL-2.0")
  ("copyright" "(c) 2018 Alexander Williams, Unscramble <license@unscramble.jp>")
  ("requires"
    ("jidoteki-admin"    "v1.20.0"    "https://github.com/on-prem/jidoteki-admin.git") ]

[de APP_HELP
  ("usage"     "network-setup.l [options]")
  ("example"   "network-setup.l --start")
  ("options"   ("--help"    "show this help message and exit")
               ("--version" "show the application version and exit")
               ("--start"   "start the application as a foreground process") ]

(setq
  *Banner_colour      "green"             # ex: green, cyan, yellow, magenta
  *Optional_settings  '(version)
  *Optional_menus     '(custom password)
  *Platform_version_t "OVA Version: "
  *App_version_t      "App Version: "
  *Reboot_for_network "no"
  *Admin_path         (if (sys "JIDO_ADMIN_PATH") @ "/opt/jidoteki/tinyadmin/")
  *Refresh_time       60000 )             # 60 seconds

(setq *Network_static '(Mode Interface Ip_address Netmask))

### External libraries
(unless *Tc_functions_loaded
  (chdir (pack *Admin_path "lib")
    (load "tc-functions.l") ) )

### Helpers

# prints a tab/spaced string
[de print-tab (Title)
  (let Length (length Title)
    (tab (list (+ 2 Length)) Title)
    (tab (list (+ 2 Length)) (pack (need Length "-"))) ]

# prints a row of network settings
# usage: (print-settings "IP Address: " "127.0.0.1" "green" "Netmask" "255.255.255.0" "white")
[de print-settings (Title1 Data1 Colour1 Title2 Data2 Colour2 Length1 Length2)
  (default Length1 14 Length2 -20)
  (prinl  (align Length1 Title1)
          (when Colour1 (colour Colour1))
          (align Length2 Data1)
          (when Colour1 (colour))
          (align 14 Title2)
          (when Colour2 (colour Colour2))
          (align -20 Data2)
          (when Colour2 (colour)) ]

# prints a row of menu options
# usage: (print-menu-option "*" 2 "DHCP" "green")
[de print-menu-option (Selected Num Title Colour)
  (prinl  (when Colour (colour Colour))
          (align 6 (pack Selected "[" Num "] "))
          (align -22 Title)
          (when Colour (colour)) ]

# prints a row for the menu validations (questions)
[de print-menu-validation (Title Value)
  (prin (align 12 Title)
        " ("
        (colour "green")
        Value
        (colour)
        "): "
        (colour "yellow") )
  (flush) ]

# prints and waits for any key to be pressed before continuing
[de print-wait-any-key ()
  (prinl  "^JPress "
          (colour "red")
          "Enter" # or any key
          (colour)
          " to continue.. " )
  (key) ]

# checks if a value is within the allowed range
# returns T if in range
# returns NIL if not in range
[de in-range? (Value Min Max)
  (and Value (>= Value Min) (<= Value Max)) ]

# checks if a string is an IPv4 address or not
# returns T if IPv4
# returns NIL if not
[de is-ipv4? (Ip_address)
  (let Ip (split (chop Ip_address) ".")
    (when (and (= 4 (length Ip)) (= 4 (length (extract format Ip))))
          T ]

# converts an IPv4 subnet mask, ex: "24" -> "255.255.255.0"
# returns the IP string if it converts
# returns NIL if it can't convert
[de cidr-to-netmask (Mask)
  (when (in-range? Mask 0 32)
        (let (Pos (- 5 (/ Mask 8))
              Val (& (>> (- (- 8 (% Mask 8))) 255) 255) )

          (glue "."
            (let N 5
              (make
                (loop
                  (cond
                    ((= N Pos) (link Val))
                    ((< N Pos) (link 0))
                    ((> N Pos) (link 255)) )
                  (T (=1 (dec 'N))) ]

# splits an IP/Mask address into a list
# returns [1] = IP, [2] = Subnet Mask
[de chop-ip-address (Ip_address)
  (mapcar pack (split (chop Ip_address) "/")) ]

### Closures

# reads dynamically bound values from environment
# returns a list of cons pairs with the network settings
[de parse-new-network-settings ()
  (make
    (mapcar '((N) (when (eval N) (link (cons (lowc N) @)))) *Network_static) ) ]

[de save-network-settings (Dhcp_static)
  (let (Mode    (if (eval Dhcp_static) @ "dhcp") # evaluate the mode, default to dhcp
        Network_new (parse-new-network-settings) )

    (colour)
    Network_new ]

### Menu input questions

[de ask-question (Network)
  (let (M 1
        Keypress (key *Refresh_time) )
    (cond
      # dynamically generated questions
      [(assoc Keypress
        (mapcar '((N)
                  (when (eval (any (pack "ask-menu-" N))) # evaluate the 'sym
                        (inc 'M)
                        (cons (format (- M 1)) N) ) )
                *Optional_menus) )
        (eval ((any (pack "ask-menu-" (cdr @) ] # evaluate and call the (sym)
      ((= (format M) Keypress) (ask-action "REBOOT"))
      ((= (format (+ M 1)) Keypress) (ask-action "POWER OFF"))
      ((= NIL Keypress) (prinl)) # noop when nothing is pressed
      (T (ask-question Network)) ] # recurse when invalid keypress is given


[de ask-action (Action)
  (prinl)
  (colour "cursor")
  (prin   "Are you sure you want to "
          (colour "red")
          (colour "bold")
          Action
          (colour)
          " ? (y/N) [default: N] " )

  (when (= "y" (lowc (key *Refresh_time)))
        (case Action
          ("REBOOT"     (call 'reboot))
          ("POWER OFF"  (call 'poweroff)) ]

### Shell commands

[de get-netmask (Ip_address Ipv4?)
  (if Ipv4?
      (cidr-to-netmask (format (cadr Ip_address)))
      (pack "/" (cadr Ip_address)) ]

[de get-ip-address (Interface)
  (chop-ip-address
    (; (mapcar pack (split (in (list "/usr/local/sbin/ip" "-o" "address" "show" "dev" Interface) (line)) " ")) 7) ]

[de get-interface ()
  (if *Interface
      @
      (setq *Interface (if  (info "/etc/sysconfig/interface")
                            (in "/etc/sysconfig/interface" (line T))
                            "eth0" ]

[de get-network-settings ()
  (let (Interface   (get-interface)
        _Ip_temp    (get-ip-address Interface)
        Ip_address  (car _Ip_temp)
        _Ipv4?      (is-ipv4? Ip_address)
        Netmask     (get-netmask _Ip_temp _Ipv4?) )

    (save-network-settings '(cdr (assoc "mode" Network))) ] # unevaluated argument

### Console display

[de show-menu (Network)
  (let Is_dhcp?  (= "dhcp" (cdr (assoc "mode" Network)))
    (print-tab "Settings menu:")

    # dynamically generated menu options
    (let M 1
      (mapcar '((N)
                (when (eval (any (pack "print-menu-" N)))     # evaluate the 'sym
                      (eval ((any (pack "print-menu-" N)) M)) # evaluate and call the (sym)
                      (inc 'M) ) )
                *Optional_menus )

      (print-menu-option NIL M "Reboot")
      (print-menu-option NIL (+ M 1) "Power Off") ]

[de show-network-settings (Network)
  (print-tab "Networking:")
  (bind (mapcar '((N) (cons N (cdr (assoc (lowc N) Network)))) *Network_static)

    (print-settings "IP Address: "  Ip_address  "green"  "Netmask: "   Netmask)

    (prinl)
    (prinl) ]

[de show-banner (Network)
  (colour *Banner_colour)
  (in "/etc/motd" (until (eof) (prinl (line T))) (prinl "^J"))
  (colour) ]

[de show-console-gui ()
  (let Network_settings (get-network-settings)
    (show-banner Network_settings)
    (show-network-settings Network_settings)
    (show-menu Network_settings)
    (ask-question Network_settings) ]

### Main

[de load-extra-scripts (Script)
  (let Filename (pack "network-setup-" Script ".l")
    (when (info Filename) (load Filename) ]

[de start-script ()
  (mapcar load-extra-scripts *Optional_menus)

  (loop
    (colour "clear")
    (colour "nocursor")
    (show-console-gui) ]

### Run

# load the --help and --version helpers
(tc-opts)

# parse the other command line options
(ifn  (= (opt) '--start)
      (and (tc-show-help) (bye))
      (native "@" "prctl" NIL 15 "network-setup")
      (call '/usr/local/bin/setterm "-blank" 0)

      (cd (pack *Admin_path "bin"))

      (start-script)
      (wait)

      (bye) )
