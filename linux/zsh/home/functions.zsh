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
  local dir="$HOME/Projects/$1"

  if [[ ! -d "$dir" ]]; then
    read -k 1 "answer?Create $dir? [Y/n] "
    [[ -z "$answer" || "$answer" == [yY] || "$answer" == $'\n' || "$answer" == $'\r' ]] || return 1
    mkdir -p "$dir" || return 1
  fi

  zed "$dir"
}

compdef _conf conf
compdef _proj proj

check-updates() {
    echo "==> Checking official repository updates (pacman)..."
    checkupdates

    echo
    echo "==> Checking AUR updates (paru)..."
    paru -Qua
}

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

evn() {
  case "$1" in
    up)
      sudo ipsec restart &&
      sleep 1 &&
      sudo ipsec up evnfc-dc &&
      sudo resolvconf -u
      ;;
    down|dn)
      sudo ipsec down evnfc-dc
      ;;
    *)
      echo "Usage: evn {up|down|dn}" >&2
      return 1
      ;;
  esac
}

cleanup-cache() {
    sudo paccache -r &&
    sudo paccache -ruk0 &&
    rm -rf ~/.cache/paru/clone/*
}
