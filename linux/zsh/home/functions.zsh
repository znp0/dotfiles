_conf() {
  _files -W "$XDG_CONFIG_HOME" -/
}

_proj() {
  _files -W "$HOME/Projects" -/
}

conf() {
  nvim "$XDG_CONFIG_HOME/$1"
}

proj() {
  zed "$HOME/Projects/$1"
}

compdef _conf conf
compdef _proj proj

dns-google() {
  sudo nmcli connection modify "$(nmcli -g NAME connection show --active | head -n1)" \
    ipv4.ignore-auto-dns yes \
    ipv6.ignore-auto-dns yes \
    ipv4.dns "8.8.8.8 8.8.4.4"

  sudo nmcli connection down "$(nmcli -g NAME connection show --active | head -n1)"
  sudo nmcli connection up "$(nmcli -g NAME connection show --active | head -n1)"
}

dns-cloudflare() {
  sudo nmcli connection modify "$(nmcli -g NAME connection show --active | head -n1)" \
    ipv4.ignore-auto-dns yes \
    ipv4.dns "1.1.1.1"

  sudo nmcli connection down "$(nmcli -g NAME connection show --active | head -n1)"
  sudo nmcli connection up "$(nmcli -g NAME connection show --active | head -n1)"
}

dns-auto() {
  sudo nmcli connection modify "$(nmcli -g NAME connection show --active | head -n1)" \
    ipv4.ignore-auto-dns no \
    ipv4.dns ""

  sudo nmcli connection down "$(nmcli -g NAME connection show --active | head -n1)"
  sudo nmcli connection up "$(nmcli -g NAME connection show --active | head -n1)"
}
