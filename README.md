# Console GUI

This repository contains the _trial_ console GUI provided for free with the [On-Prem Trial OVA](https://try.on-premises.com)

![on-prem-console-1](https://user-images.githubusercontent.com/153401/37279346-720c8a96-25e2-11e8-85c4-8c0d2bbf2463.jpg)

The _trial_ console GUI is a simplified version of the _On-Prem Enterprise_ console GUI, as it doesn't include the ability to configure or change any settings other than the `admin` password.

# Download Enterprise

To obtain the _Enterprise_ console GUI, as well as help with building an _Enterprise OVA_, please visit [on-premises.com](https://on-premises.com) and contact us for pricing and support plans.

# Requirements

  * [PicoLisp](https://github.com/picolisp/picolisp.git) - 32-bit or 64-bit v3.1.11+
  * [jidoteki-admin](https://github.com/on-prem/jidoteki-admin.git) - v1.20.0+ lib deployment (Ansible `--tags=lib`)
  * Linux tools:
    * `/usr/local/sbin/ip` (iproute2)
    * `/usr/local/bin/setterm` (util-linux)
    * `/usr/local/bin/tput` (ncurses-bin)

# Getting Started

### 1. Ensure `jidoteki-admin` is installed

Ensure the `jidoteki-admin` libs are installed in `/opt/jidoteki/tinyadmin/` (default), or export the install directory with the `JIDO_ADMIN_PATH` environment variable.

### 2. Copy the scripts

Add `network-setup.l` and `network-setup-password.l` to the `bin/` directory of your `jidoteki-admin` installation directory (ex: `/opt/jidoteki/tinyadmin/bin/`)

### 3. Run the script

Run the script with the `--start` option, ex: `/opt/jidoteki/tinyadmin/bin/network-setup.l --start`

### 4. Bonus

The console terminal (getty) can be replaced by adding the start command to `/etc/inittab`. There is no support for `systemd`

# How it works

Once running, the script will read the IP address, subnet mask, motd, and display them in the console GUI. Through simple menu options 1-3, it is possible to change the admin password, reboot, or shutdown the OVA. The display will refresh every 60 seconds, in case the settings change behind the scenes (DHCP?).

# The code

The _network-setup_ script was originally written in Bash, in 2013. Things have evolved since then, and the current iteration is written in _PicoLisp_.

The script uses a series of helpers found in `tc-functions.l` (included with `jidoteki-admin v1.20.0+`), and defines its own helpers, which are divided into six sub-sections:

  * **printing:** functions prefixed with `(print-` which are used by other functions to display things on the screen, ex: `(print-menu-option)`
  * **networking:** functions which work on IPv4 and IPv6 addresses, ex: `(is-ipv4?)`
  * **closures:** functions which read dynamically bound values from its environment
  * **questions:** functions prefixed with `(ask-` which display and act on various menu questions, ex: `(ask-question)`
  * **commands:** functions prefixed with `(get-` which call shell commands and return the parsed results, ex `(get-ip-address)`
  * **menus:** functions prefixed with `(show-` which display various menus and output on the console, ex: `(show-network-settings)`

Certain functions are dynamically loaded from additional files, such as `network-setup-password.l`. Additional menus and options can be defined through the `*Optional_settings` and `*Optional_menus` variables at the top of the script.

Variations of the same scripts [are deployed](https://on-premises.com) to different customers with unique requirements and features, which is why the scripts contain a series of hardcoded and dynamic values, as most functions were pulled from the _Enterprise_ console GUI. This may lead to confusion as our intention was not to make this a generic tool for the public.

# Screenshots

### Trial OVA Console GUI

![on-prem-console-1](https://user-images.githubusercontent.com/153401/37279346-720c8a96-25e2-11e8-85c4-8c0d2bbf2463.jpg) ![on-prem-console-2](https://user-images.githubusercontent.com/153401/37279347-7331fb22-25e2-11e8-83a4-d0e59423880d.jpg)

### Meta Enterprise OVA Console GUI

![on-prem-console-3](https://user-images.githubusercontent.com/153401/37279348-7390708a-25e2-11e8-9084-0f3e61cfdb8e.jpg) ![on-prem-console-4](https://user-images.githubusercontent.com/153401/37280108-becc3046-25e4-11e8-99d1-e2adeac74506.jpg)

# Why network-setup?

The script was originally intended to perform the initial "setup" of the "network". The _Enterprise_ console GUI provides those functions and more, however this _trial_ version is limited to only displaying the IP address and subnet mask.

# Contributing

There is no need for pull requests, feature requests, or bug reports, since these scripts are actively maintained. If, however, you do modify these scripts, please comply with the [MPL-2.0 License](LICENSE) and make your changes publicly available in order for everyone to benefit.

# License

[MPL-2.0 License](LICENSE)

Copyright (c) 2018 Alexander Williams, Unscramble <license@unscramble.jp>
