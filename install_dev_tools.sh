#!/usr/bin/env bash
# install_dev_tools.sh
# Автоматична інсталяція Docker, Docker Compose, Python (>=3.9) та Django
# Працює на Ubuntu/Debian. Ідемпотентний.

set -euo pipefail

# ---------- утиліти ----------
GREEN="\e[32m"; YELLOW="\e[33m"; RED="\e[31m"; NC="\e[0m"
say()  { echo -e "${GREEN}==>${NC} $*"; }
warn() { echo -e "${YELLOW}==>${NC} $*"; }
die()  { echo -e "${RED}ERROR:${NC} $*" >&2; exit 1; }

SUDO=""
if [[ $EUID -ne 0 ]]; then SUDO="sudo"; fi

need_cmd() {
  command -v "$1" >/dev/null 2>&1
}

# ---------- Docker repo (офіційний) ----------
ensure_docker_repo() {
  if ! apt-cache policy 2>/dev/null | grep -q 'download.docker.com'; then
    say "Додаю офіційний репозиторій Docker…"
    $SUDO apt-get update -y
    $SUDO apt-get install -y ca-certificates curl gnupg lsb-release
    $SUDO install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
      | $SUDO gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    $SUDO chmod a+r /etc/apt/keyrings/docker.gpg

    codename="$($SUDO bash -lc 'source /etc/os-release; echo $VERSION_CODENAME')"
    echo "deb [arch=$(dpkg --print-architecture) \
signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
$codename stable" | $SUDO tee /etc/apt/sources.list.d/docker.list >/dev/null

    $SUDO apt-get update -y
  fi
}

# ---------- Docker ----------
install_docker() {
  if need_cmd docker; then
    say "Docker вже встановлено: $(docker --version)"
  else
    say "Встановлюю Docker…"
    ensure_docker_repo
    $SUDO apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin
    say "Додаю поточного користувача до групи docker (щоб працювати без sudo)…"
    $SUDO usermod -aG docker "$USER" || true
  fi
}

# ---------- Docker Compose ----------
install_docker_compose() {
  # Підійде як плагін `docker compose`, так і класичний `docker-compose`
  if docker compose version >/dev/null 2>&1; then
    say "Docker Compose вже встановлено: $(docker compose version)"
  elif need_cmd docker-compose; then
    say "Docker Compose (standalone) вже встановлено: $(docker-compose --version)"
  else
    say "Встановлюю Docker Compose (docker-compose-plugin)…"
    ensure_docker_repo
    $SUDO apt-get install -y docker-compose-plugin
    say "Перевірка: $(docker compose version)"
  fi
}

# ---------- Python (>=3.9) ----------
install_python() {
  local need_new=0
  if need_cmd python3; then
    cur="$(python3 -V 2>&1 | awk '{print $2}')"
    # Порівняння версій через dpkg:
    if dpkg --compare-versions "$cur" lt "3.9"; then
      need_new=1
    fi
  else
    need_new=1
  fi

  if [[ $need_new -eq 1 ]]; then
    say "Встановлюю Python 3.9+ і pip…"
    $SUDO apt-get update -y
    $SUDO apt-get install -y python3 python3-pip
  else
    say "Python вже є ($(python3 -V)); pip: $(python3 -m pip -V 2>/dev/null || echo 'відсутній')"
    $SUDO apt-get install -y python3-pip
  fi
}

# ---------- Django через venv ----------
install_django() {
  say "Готую віртуальне середовище для Python/Django…"

  # встановимо модуль venv, якщо його немає
  $SUDO apt-get update -y
  $SUDO apt-get install -y python3-venv

  VENV_DIR="${HOME}/.venvs/devtools"
  mkdir -p "${HOME}/.venvs"

  # створимо venv, якщо ще не існує
  if [[ ! -x "${VENV_DIR}/bin/python" ]]; then
    python3 -m venv "${VENV_DIR}"
  fi

  # оновимо pip/setuptools і поставимо Django усередині venv
  "${VENV_DIR}/bin/python" -m pip install -U pip setuptools wheel
  if "${VENV_DIR}/bin/python" -m pip show django >/dev/null 2>&1; then
    say "Django вже встановлено у venv: $("${VENV_DIR}/bin/python" -m django --version)"
  else
    say "Встановлюю Django у venv…"
    "${VENV_DIR}/bin/python" -m pip install -U django
    say "Django версія: $("${VENV_DIR}/bin/python" -m django --version)"
  fi

  # підкажемо, як користуватись
  echo
  say "Щоб працювати з Django, активуй середовище:"
  echo "  source ${VENV_DIR}/bin/activate"
  echo "Після активації: python -m django --version, django-admin, тощо."
}

# ---------- main ----------
main() {
  install_docker
  install_docker_compose
  install_python
  install_django
  say "Готово! Можливо, потрібно перелогінитись, щоб група docker застосувалася."
}

main "$@"
