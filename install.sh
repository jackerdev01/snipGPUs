#!/usr/bin/env bash
# snipGPU - cai dat 1 lenh tren VPS / Linux:
#   curl -fsSL https://raw.githubusercontent.com/jackerdev01/snipGPUs/main/install.sh | bash
# Tu cai Docker (neu chua co), hoi token/key/vi, luu vao ~/snipgpu/data/.env (chi ban doc duoc), chay bot nen va
# tu chay lai khi VPS khoi dong lai. Chay lai script bat ky luc nao de doi key/vi hoac cap nhat ban moi.
# Khong hoi (tu dong hoa): truyen bien moi truong, vd  curl ... | TELEGRAM_BOT_TOKEN=... PRL_WALLET=... bash
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/jackerdev01/snipGPUs/main"
DIR="${SNIPGPU_DIR:-$HOME/snipgpu}"
ENV_FILE="$DIR/data/.env"

say()  { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31mLoi:\033[0m %s\n' "$*" >&2; exit 1; }

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  command -v sudo >/dev/null || fail "can quyen root hoac sudo"
  SUDO="sudo"
fi

# 1. Docker
if ! command -v docker >/dev/null; then
  say "Cai Docker..."
  curl -fsSL https://get.docker.com | $SUDO sh
fi
$SUDO docker compose version >/dev/null 2>&1 || fail "can Docker Compose v2 (docker compose)"

mkdir -p "$DIR/data"
cd "$DIR"

# 2. Gia tri da luu lan truoc (chay lai script thi chi can Enter de giu nguyen)
current() { [ -f "$ENV_FILE" ] && grep -E "^$1=" "$ENV_FILE" | tail -n1 | cut -d= -f2- || true; }

TTY=/dev/tty
ask() {   # ask NAME "cau hoi" [secret]
  local name="$1" prompt="$2" secret="${3:-}" def val shown
  def="${!name:-$(current "$name")}"
  if [ -n "${!name:-}" ] || [ ! -r "$TTY" ]; then
    printf -v "$name" '%s' "$def"; return
  fi
  shown="$def"
  if [ -n "$def" ] && [ -n "$secret" ]; then shown="${def:0:4}...${def: -4}"; fi
  if [ -n "$secret" ]; then
    read -r -s -p "$prompt${shown:+ [$shown]}: " val < "$TTY"; echo > "$TTY"
  else
    read -r -p "$prompt${shown:+ [$shown]}: " val < "$TTY"
  fi
  printf -v "$name" '%s' "${val:-$def}"
}

echo
say "Nhap thong tin (Enter = giu gia tri trong ngoac, de trong = khong dung)"
ask TELEGRAM_BOT_TOKEN "Telegram bot token (tu @BotFather)" secret
ask TELEGRAM_CHAT_ID   "Telegram chat ID (tu @userinfobot)"
ask PRL_WALLET         "Vi PRL (prl1...)"
ask QTC_WALLET         "Vi QTC (qz..., Enter de bo qua)"
echo "   Chua co tai khoan? Vast.ai:  https://cloud.vast.ai/?ref_id=716525"
echo "                      Clore.ai: https://clore.ai/register?ref_id=6ph9tvyq"
echo "                      QuickPod: https://console.quickpod.io?affiliate=303bbe95-4783-4a7d-ad33-98a8da2aec40"
ask VAST_API_KEY       "Vast.ai API key" secret
ask CLORE_API_KEY      "Clore.ai API key" secret
ask QUICKPOD_API_KEY   "QuickPod API key" secret
ask SALAD_API_KEY      "SaladCloud API key" secret
if [ -n "$SALAD_API_KEY" ]; then
  ask SALAD_ORG     "SaladCloud organization"
  ask SALAD_PROJECT "SaladCloud project"
else
  SALAD_ORG="$(current SALAD_ORG)"; SALAD_PROJECT="$(current SALAD_PROJECT)"
fi

[ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ] || fail "can Telegram token va chat ID"
[ -n "$PRL_WALLET" ] || fail "can vi PRL"
[ -n "$VAST_API_KEY$CLORE_API_KEY$QUICKPOD_API_KEY$SALAD_API_KEY" ] || fail "can it nhat 1 API key (Vast/Clore/QuickPod/Salad)"

# 3. Luu .env (giu cac dong khac neu da co)
umask 077
touch "$ENV_FILE"
for name in TELEGRAM_BOT_TOKEN TELEGRAM_CHAT_ID PRL_WALLET QTC_WALLET VAST_API_KEY CLORE_API_KEY QUICKPOD_API_KEY \
            SALAD_API_KEY SALAD_ORG SALAD_PROJECT; do
  grep -vE "^$name=" "$ENV_FILE" > "$ENV_FILE.tmp" || true
  printf '%s=%s\n' "$name" "${!name}" >> "$ENV_FILE.tmp"
  mv "$ENV_FILE.tmp" "$ENV_FILE"
done
chmod 600 "$ENV_FILE"
umask 022

# 4. Chay
say "Tai ban moi nhat va khoi dong..."
curl -fsSL "$REPO_RAW/docker-compose.yml" -o docker-compose.yml
$SUDO docker compose pull
$SUDO docker compose up -d --force-recreate
sleep 8
$SUDO docker compose logs --tail 20

echo
say "Xong. Bot dang chay nen, tu chay lai khi VPS khoi dong lai."
echo "   Thu muc:   $DIR  (cau hinh: $DIR/data/config_*.yaml)"
echo "   Xem log:   cd $DIR && $SUDO docker compose logs -f"
echo "   Dung:      cd $DIR && $SUDO docker compose down"
echo "   Telegram:  gui /status cho bot. Bot bat dau o che do CHAY THU (chi bao, khong thue)."
