# snipGPU

A bot that hunts for cheap GPUs on **[Vast.ai](https://cloud.vast.ai/?ref_id=716525), [Clore.ai](https://clore.ai/register?ref_id=6ph9tvyq), [QuickPod](https://console.quickpod.io?affiliate=303bbe95-4783-4a7d-ad33-98a8da2aec40) and SaladCloud** to mine **PRL** (PearlHash) and **QTC** (Quantus) on the Kryptex pool. It:

- scans prices continuously and prices every machine against the pool's real revenue;
- rents a machine when its profit clears the threshold you set, then installs and starts the miner;
- measures the real hashrate and can switch to the more profitable coin (optional);
- gives a machine back when profit drops, the miner fails or the hashrate is weak;
- reports to you and takes commands on **Telegram**.

Download the builds from **[Releases](../../releases/latest)**. This repository holds only the guide and sample files, no source code.

---

## ⚡ One-command install

Have these ready: your **Telegram bot token**, your **chat ID**, a **PRL wallet** and the **API key** of each platform you use. [Section 1](#1-prerequisites) shows where to get each one.

**VPS / Linux.** The script installs Docker, asks for each value, then runs the bot in the background:

```bash
curl -fsSL https://raw.githubusercontent.com/jackerdev01/snipGPUs/main/install.sh | bash
```

**Windows.** Open **PowerShell** and paste the command below. The script downloads `snipgpu.exe`, asks for each value, starts the bot and sets it to start when you sign in to Windows:

```powershell
irm https://raw.githubusercontent.com/jackerdev01/snipGPUs/main/install.ps1 | iex
```

**Docker in one line.** Replace the values, then run:

```bash
docker run -d --name snipgpu --restart unless-stopped -v ~/snipgpu/data:/data \
  -e TELEGRAM_BOT_TOKEN=123456:AAxxx -e TELEGRAM_CHAT_ID=123456789 \
  -e PRL_WALLET=prl1xxx -e VAST_API_KEY=xxx \
  ghcr.io/jackerdev01/snipgpu:latest
```

For other platforms add `-e CLORE_API_KEY=...`, `-e QUICKPOD_API_KEY=...`, or `-e SALAD_API_KEY=... -e SALAD_ORG=... -e SALAD_PROJECT=...`. Add `-e QTC_WALLET=qz...` to mine QTC.

**Standalone program, miner style** (Windows `snipgpu.exe` / Linux `snipgpu-linux`):

```bash
./snipgpu --telegram-token 123456:AAxxx --chat-id 123456789 --prl-wallet prl1xxx --vast-key xxx
```

Other options: `--qtc-wallet`, `--clore-key`, `--quickpod-key`, `--salad-key`, `--salad-org`, `--salad-project`. The bot saves them to `data/.env`, so **next time just run `./snipgpu`**.

Once it runs, Telegram receives a **"🤖 snipGPU khởi động"** (started) message. The bot starts in **dry run** (it reports, it does not rent). See [section 4](#4-dry-run-then-go-live) to start renting.

> 🔒 Keys typed on the command line stay in your shell history. `install.sh` / `install.ps1` ask for them instead, which is safer. If you typed keys on the command line, clear the history with `history -c` (Linux).

The sections below are the detailed guide and the settings you can change.

---

## Contents

1. [Prerequisites](#1-prerequisites)
2. [Install: pick one of three ways](#2-install)
   - [A. Docker on a VPS / Linux](#a-docker-on-a-vps--linux-recommended)
   - [B. Windows (.exe)](#b-windows-exe)
   - [C. Linux without Docker](#c-linux-without-docker)
3. [Configuration](#3-configuration)
4. [Dry run, then go live](#4-dry-run-then-go-live)
5. [Telegram commands](#5-telegram-commands)
6. [Common settings](#6-common-settings)
7. [Update, back up, move to another machine](#7-update-back-up-move-to-another-machine)
8. [Troubleshooting](#8-troubleshooting)

---

## 1. Prerequisites

| You need | Notes |
|---|---|
| A machine running 24/7 | A Linux VPS with 1 vCPU / 1 GB RAM is enough, or a Windows PC that stays on. It **needs no GPU**: the bot rents GPUs on the platforms. |
| A Telegram bot | Message [@BotFather](https://t.me/BotFather) and send `/newbot` to get a **token** like `123456789:AA...`. Then **send any message to your new bot**, or it cannot message you. |
| Your Telegram chat ID | Message [@userinfobot](https://t.me/userinfobot); it replies `Id: 123456789`. |
| A PRL wallet | An address starting with `prl1...` |
| A QTC wallet | Only if you mine QTC. An address starting with `qz...` |
| An account with funds on **at least one** platform | See the table below |

Sign up and get an API key on each platform:

| Platform | Sign up | Where to find the key | Notes |
|---|---|---|---|
| **Vast.ai** | [Sign up for Vast.ai](https://cloud.vast.ai/?ref_id=716525) | Account → **API Keys** → Create | Add credit first. |
| **Clore.ai** | [Sign up for Clore.ai](https://clore.ai/register?ref_id=6ph9tvyq) | Profile → **API** | Add a USD (or CLORE) balance. |
| **QuickPod** | [Sign up for QuickPod](https://console.quickpod.io?affiliate=303bbe95-4783-4a7d-ad33-98a8da2aec40) | Account → **API Key** | |
| **SaladCloud** | [portal.salad.com](https://portal.salad.com/) | Account → **API Access** | Also needs your **organization name** and **project name**: create a project in the portal; both names are in the URL `portal.salad.com/organizations/<org>/projects/<project>`. |

Skip the platforms you do not use.

---

## 2. Install

### A. Docker on a VPS / Linux (recommended)

**Step 1. Install Docker** (skip if it is already installed):

```bash
curl -fsSL https://get.docker.com | sh
```

**Step 2. Download the compose file and start once:**

```bash
mkdir -p ~/snipgpu && cd ~/snipgpu
curl -fsSLO https://raw.githubusercontent.com/jackerdev01/snipGPUs/main/docker-compose.yml
docker compose up -d
docker compose logs
```

On the first start the bot creates `~/snipgpu/data` with `.env`, `config_*.yaml` and `ssh/`, prints what you still have to fill in, and retries a few seconds later.

**Step 3.** Fill in the configuration as in [section 3](#3-configuration):

```bash
nano data/.env
nano data/config_vast.yaml      # and the config_*.yaml of each platform you use
```

**Step 4.** Restart and watch the log:

```bash
docker compose restart
docker compose logs -f          # Ctrl+C stops watching; the bot keeps running
```

When it runs, Telegram receives the **"🤖 snipGPU khởi động"** (started) message. The bot comes back by itself after the VPS reboots.

> **Windows with Docker Desktop** works the same way in PowerShell. In step 2, download the file with:
> `curl.exe -fsSLO https://raw.githubusercontent.com/jackerdev01/snipGPUs/main/docker-compose.yml`

### B. Windows (.exe)

1. Download **[snipgpu.exe](../../releases/latest/download/snipgpu.exe)**.
2. Create a folder for it, for example `C:\snipgpu\`, and put `snipgpu.exe` there.
3. **Run `snipgpu.exe`** (double-click). The first time it creates `C:\snipgpu\data\`, lists what is missing, and waits for Enter to close.
4. Open `data\.env` and `data\config_*.yaml` in Notepad and fill them in as in [section 3](#3-configuration).
5. Run `snipgpu.exe` again. Closing the console window stops the bot.

Notes:

- **Windows SmartScreen** may say "Windows protected your PC" because the file is not signed. Click **More info → Run anyway**.
- Some antivirus programs flag compiled Python programs by mistake. If it is blocked, add `C:\snipgpu` to the exclusions.
- **Start with Windows:** press `Win+R`, type `shell:startup`, and create a shortcut to `C:\snipgpu\snipgpu.exe` in that folder.
- Turn off Windows **Sleep**. A sleeping PC stops the bot, but rented machines keep billing.

### C. Linux without Docker

The build needs **Ubuntu 22.04+ / Debian 12+** (x86_64).

```bash
mkdir -p ~/snipgpu && cd ~/snipgpu
curl -fsSLo snipgpu https://github.com/jackerdev01/snipGPUs/releases/latest/download/snipgpu-linux
chmod +x snipgpu
./snipgpu            # first run: creates ./data, then exits
nano data/.env       # fill in as in section 3
./snipgpu            # run in the foreground, Ctrl+C to stop
```

To run it in the background and start it again after a reboot, create a systemd service:

```bash
sudo tee /etc/systemd/system/snipgpu.service >/dev/null <<EOF
[Unit]
Description=snipGPU
After=network-online.target
Wants=network-online.target

[Service]
User=$USER
WorkingDirectory=$HOME/snipgpu
ExecStart=$HOME/snipgpu/snipgpu
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now snipgpu
journalctl -u snipgpu -f        # watch the log
```

---

## 3. Configuration

Everything that is yours lives in the **`data`** folder, next to the program or in `~/snipgpu/data` with Docker.

### 3.1. `data/.env`: keys and Telegram

```ini
TELEGRAM_BOT_TOKEN=123456789:AAxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TELEGRAM_CHAT_ID=123456789

VAST_API_KEY=xxxxxxxx            # empty = Vast not used
CLORE_API_KEY=
QUICKPOD_API_KEY=
SALAD_API_KEY=
SALAD_ORG=
SALAD_PROJECT=
```

- `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` are **required**.
- At least **one** platform key is required. The bot skips a platform whose key is empty.
- No quotes and no spaces around `=`.

### 3.2. Mining wallets

**Simplest:** put your wallets in `data/.env`. On every start the bot writes them into every config file:

```ini
PRL_WALLET=prl1qxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
QTC_WALLET=qzxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx      # only to mine QTC
```

When `PRL_WALLET` / `QTC_WALLET` are set, they **always win** over the wallets in the config files. To change a wallet, edit `.env` and restart the bot.

**Or** fill each config file by hand. Each platform has its own: `config_vast.yaml`, `config_clore.yaml`, `config_quickpod.yaml`, `config_salad.yaml`. In the file of **each platform you use**, find the lines:

```yaml
  wallet: ""   # BAT BUOC: dien dia chi vi cua ban
```

(the comment means "REQUIRED: your wallet address") and fill them in by the section they are in:

| `wallet:` line under | Value |
|---|---|
| `miner:` | Your **PRL** wallet (`prl1...`) |
| `qtc:` | Your **QTC** wallet (`qz...`). Only required with `qtc.enabled: true` in the same file. |

Example:

```yaml
miner:
  wallet: "prl1qxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

If a wallet or key is missing, the bot **does not start** and prints exactly what is missing.

> YAML is **indented with spaces**. Change only the value after `:`; do not remove the leading spaces and do not use Tab.

### 3.3. SSH key (handled by the bot)

On the first run the bot creates `data/ssh/id_ed25519` and attaches it to the machines it rents, to measure the hashrate and switch coins. Nothing to do. **Do not delete this folder** while machines are rented, or the bot loses access to them.

---

## 4. Dry run, then go live

Every platform starts in **dry run** (`dry_run: true`): the bot scans prices and **reports opportunities on Telegram** but **does not rent and spends nothing**.

Let it run dry for a few hours to see which machines it picks and the estimated profit. When you are happy, go live **per platform** from Telegram:

| Platform | Go live | Back to dry run |
|---|---|---|
| Vast | `/set vast dry_run false` | `/set vast dry_run true` |
| Clore | `/clore live` | `/clore dry` |
| QuickPod | `/quick live` | `/quick dry` |
| Salad | `/salad live` | `/salad dry` |

You can also set `dry_run: false` in the config file and restart the bot.

**Set limits before going live**, for example one machine at first:

```text
/set vast rent.max_machines 1
/set clore rent.max_machines 1
```

---

## 5. Telegram commands

Send `/help` for the full list. The most used:

| Command | What it does |
|---|---|
| `/status` | Bot state, balances, machines rented |
| `/report` | Profit/loss per machine, coin comparison |
| `/pods` | Machines rented |
| `/config` | Main settings of every platform |
| `/set <platform> <key> <value>` | Change a setting at once, no restart. Example: `/set vast rent.max_machines 2` |
| `/unset <platform> <key>` | Back to the value in the config file |
| `/pause` / `/resume` | Stop / resume renting new machines on every platform (rented machines stay watched). Add a platform to limit it: `/pause clore` |
| `/stop <platform> <id>` | Give a machine back now and do not rent it again for 24 hours |
| `/clore`, `/quick`, `/salad` | State of one platform |
| `/bans` | Banned machines |
| `/unban <platform> machine <id>` | Unban a machine |

`<platform>` is one of `vast`, `clore`, `quick`, `salad`. The bot only takes commands from your own `TELEGRAM_CHAT_ID`, in your private chat with it. Bot messages are in Vietnamese.

---

## 6. Common settings

Change them on Telegram with `/set <platform> <key> <value>` (effective at once, saved in `data/*_override.yaml`), or edit `config_*.yaml` and restart the bot. Each platform has its own settings, and some keys exist on some platforms only: send `/config <platform>` to see them all.

| Key | Meaning | Default |
|---|---|---|
| `rent.max_machines` | Most machines rented at once | 1 |
| `rent.max_price_hour` | Price cap in $/hour for the whole machine (`null` = no cap) | null |
| `rent.coins.PRL` / `rent.coins.QTC` | Allow renting to mine that coin | true |
| `profit.min_profit_by_coin.PRL` | Minimum profit to **rent** for PRL (0.05 = 5%) | 0.05 |
| `profit.min_profit_by_coin.QTC` | Minimum profit to **rent** for QTC | 0.10 |
| `monitor.min_profit_by_coin.PRL` | A machine whose measured profit stays under this is **given back** | 0.0 |
| `qtc.enabled` | Mine QTC (needs a QTC wallet) | per platform |
| `qtc.auto_switch` | Switch coin when the other one clearly pays more | false |
| `filters.countries_exclude` | Skip machines in these countries | `[CN]` |
| `modes` (Vast) | `[ondemand]` (fixed price), or add `interruptible` (bid: cheaper, may be stopped) | `[ondemand]` |

Profit is `(revenue − cost) / cost`. Revenue comes from the Kryptex pool at the current coin price, after the pool fee.

Examples:

```text
/set vast rent.max_machines 3
/set vast profit.min_profit_by_coin.PRL 0.10
/set clore qtc.enabled true
```

Wallets and pool addresses **cannot be changed from Telegram**: even someone who took over your Telegram chat could not send your coins elsewhere. Change them in the config file and restart the bot.

---

## 7. Update, back up, move to another machine

**Update.** Your configuration in `data` is always kept.

- Docker: `docker compose pull && docker compose up -d`
- Windows / Linux: download the new file from [Releases](../../releases/latest), stop the bot, replace the old program, start it again. Or run the install command again.

A new version never overwrites your config files. To get a newer sample config, rename yours (for example `config_vast.old.yaml`), run the bot once so it creates a fresh one, then copy your wallets and settings over.

**Back up / move.** Copying the whole `data` folder to the new machine is enough: it holds your keys, wallets, SSH key and the machines being rented. **Never run two bots on the same `data` or the same Telegram token**: they would fight over the machines.

**Security.** `data/.env` and `data/ssh/` are secrets: do not share them.

---

## 8. Troubleshooting

| Symptom | Fix |
|---|---|
| The bot prints "Can dien truoc khi chay" (fill in before running) and stops | Fill in the listed items and run it again. |
| No Telegram messages | Check the token and chat ID, and make sure you **messaged the bot first** (press Start). |
| The log shows `HTTP 401` / `403` | Wrong API key, or the key was deleted on the platform. |
| Opportunities are reported but nothing is rented | Dry run (`dry_run`), no balance left, `rent.max_machines` reached, or `/pause`. Send `/status` to see why. |
| No opportunities at all | No machine on the market clears your profit threshold. You can lower `profit.min_profit_by_coin.*`, at more risk. |
| A rented machine is given back after a few minutes | It could not run the miner (old driver, GitHub blocked) or its hashrate was low. The bot bans it; this is normal. |
| Docker: `permission denied` on `data` | Run `sudo chown -R $USER data`, or run docker with `sudo`. |
| Windows: the window opens and closes at once | Open `cmd`, `cd C:\snipgpu`, and run `snipgpu.exe` to read the error. |

The bot's log is `data/snipvast.log`, rotated at 3 files × 5 MB.

> ⚠️ **Risk:** renting GPUs to mine can lose money when coin prices or difficulty change. The bot only rents above your profit threshold and gives machines back at a loss, but profit is not guaranteed. Start small and watch `/report`.

---

⚡ Powered by [Hunter](https://t.me/nguyenhung2310)
