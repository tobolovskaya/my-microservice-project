#!/usr/bin/env bash
# install_dev_tools.sh
# Автоматичне встановлення Docker, Docker Compose, Python (>=3.9) та Django
# Підходить для Ubuntu/Debian. Скрипт ідемпотентний.

set -euo pipefail

# ---------- утиліти ----------
GREEN="\e[32m"; YELLOW="\e[33m"; RED="\e[31m"; NC="\e[0m"
say()  { echo -e "${GREEN}==>${NC} $*"; }
warn() { echo -e "${YELLOW}==> $*${NC}"; }
die()  { echo -e "${RED}ERROR:${NC} $*" >&2; exit 1; }

need_cmd() { command -v "$1" >/dev/null 2>&1; }
ver() { printf "%03d%03d%03d\n" $(echo "${1:-0.0.0}" | tr '.' ' '); }

require_apt() {
  need_cmd apt-get || die "Це не схоже на Ubuntu/Debian (apt-get не знайдено)."
}

require_sudo() {
  if [[ $EUID -ne 0 ]]; then
    need_cmd sudo || die "Потрібні права root або пакет sudo."
    SUDO="sudo"
  else
    SUDO=""
  fi
}

apt_update_once() {
  # запускаємо update лише один раз
  if [[ -z "${APT_UPDATED:-}" ]]; then
    say "Оновлюю кеш пакетів apt..."
    $SUDO apt-get update -y
    APT_UPDATED=1
  fi
}

# ---------- Docker + Compose ----------
install_docker() {
  if need_cmd docker; then
    say "Docker вже встановлено: $(docker --version)"
  else
    say "Встановлюю Docker CE з офіційного репозиторію..."
    apt_update_once
    $SUDO apt-get install -y ca-certificates curl gnupg lsb-release
    # ключ і репозиторій
    if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
      $SUDO install -m 0755 -d /etc/apt/keyrings
      curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | \
        $SUDO gpg --dearmor -o /etc/apt/keyrings/docker.gpg
      $SUDO chmod a+r /etc/apt/keyrings/docker.gpg
    fi
    echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
$($SUDO bash -lc 'source /etc/os-release; echo $VERSION_CODENAME') stable" | \
      $SUDO tee /etc/apt/sources.list.d/docker.list >/dev/null

    apt_update_once
    $SUDO apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    $SUDO systemctl enable --now docker
    # додати поточного користувача до групи docker (щоб працювати без sudo)
    if getent group docker >/dev/null; then
      $SUDO usermod -aG docker "${SUDO_USER:-$USER}" || true
      warn "Щоб працювати з docker без sudo, перелогінься або виконай: newgrp docker"
    fi
  fi

  # Compose  (docker compose)
  install_docker_compose() {
    if command -v docker-compose &>/dev/null || docker compose version &>/dev/null; then
        say "Docker Compose вже встановлено: $(docker compose version 2>/dev/null || docker-compose --version)"
    else
        say "Встановлюю Docker Compose..."
        sudo apt-get update
        sudo apt-get install -y curl gnupg lsb-release

        # Додаємо офіційний репозиторій Docker
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          $(lsb_release -cs) stable" | \
          sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        sudo apt-get update
        sudo apt-get install -y docker-compose-plugin
    fi
}


# ---------- Python (>=3.9) ----------
install_python() {
  local need_new=0 cur="0.0.0"

  if need_cmd python3; then
    cur="$(python3 --version 2>&1 | awk '{print $2}')"
    [[ $(ver "$cur") -lt $(ver "3.9.0") ]] && need_new=1
  else
    need_new=1
  fi

  if [[ $need_new -eq 0 ]]; then
    say "Python вже є (${cur}), pip: $(python3 -m pip --version 2>/dev/null || echo 'немає')"
  else
    say "Встановлюю Python 3 (намагаюся отримати >= 3.9)…"
    apt_update_once
    # на більшості підтримуваних Ubuntu/Debian цього достатньо:
    $SUDO apt-get install -y python3 python3-pip python3-venv
    if need_cmd python3; then
      cur="$(python3 --version 2>&1 | awk '{print $2}')"
    fi
    if [[ $(ver "$cur") -lt $(ver "3.9.0") ]]; then
      warn "Стандартні репозиторії дають Python ${cur} < 3.9 — підключаю PPA deadsnakes…"
      $SUDO apt-get install -y software-properties-common
      $SUDO add-apt-repository -y ppa:deadsnakes/ppa
      apt_update_once
      $SUDO apt-get install -y python3.10 python3.10-venv python3-pip
      $SUDO update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 2 || true
    fi
    say "Python тепер: $(python3 --version 2>&1)"
  fi
}

# ---------- Django ----------
install_django() {
  if python3 -m pip show django >/dev/null 2>&1; then
    say "Django вже встановлено: версія $(python3 -m django --version 2>/dev/null || echo '?')"
  else
    say "Встановлюю Django через pip…"
    python3 -m pip install --upgrade pip >/dev/null 2>&1 || true
    python3 -m pip install Django
    say "Django встановлено: версія $(python3 -m django --version)"
  fi
}

# ---------- main ----------
require_apt
require_sudo
install_docker
install_python
install_django

say "Готово! ✅"
echo -e "${YELLOW}Якщо вас додали до групи docker — перелогіньтесь або виконайте: newgrp docker${NC}"
