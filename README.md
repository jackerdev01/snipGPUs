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
6. [Settings](#6-settings)
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

## 6. Settings

These are the settings `/config` shows on Telegram, which you can change with `/set`.

### 6.1. How settings work

- **Telegram:** `/config <platform>` lists the settings below with their current values (`*` = changed from Telegram). `/set <platform> <key> <value>` changes one at once, no restart. It is saved in `data/` (`config_override.yaml` for Vast, `clore_override.yaml`, `quick_override.yaml`, `salad_override.yaml`) and wins over the config file. `/unset <platform> <key>` goes back to the file's value.
- **File:** the same keys are in `data/config_vast.yaml`, `config_clore.yaml`, `config_quickpod.yaml` and `config_salad.yaml`. Edit the file, then restart the bot.

Conventions:

- **Profit** is `(revenue − cost) / cost`, written as a fraction: `0.05` = 5%, `-0.1` = a 10% loss. Revenue is the Kryptex pool's daily revenue at the current coin price, after the pool fee; cost is what the platform bills (GPUs, disk and the platform's fee).
- `null` means "not set" (for example no price cap).
- Wallets and pool addresses **cannot be changed from Telegram**, so someone who took over your chat cannot send your coins elsewhere: see [section 3.2](#32-mining-wallets).
- A key marked with platforms (for example *(Vast, Clore)*) exists on those platforms only; unmarked keys exist on all four. *Defaults* are the values in the sample files, given as Vast / Clore / QuickPod / Salad when they differ.

Examples:

```text
/set vast rent.max_machines 3
/set vast profit.min_profit_by_coin.PRL 0.10
/set clore qtc.enabled true
/set salad rent.max_spend_hour 2
```

### 6.2. General

| Key | Meaning | Default |
|---|---|---|
| `dry_run` | `true`: scan and report opportunities only, never rent. `false`: rent for real. | `true` |
| `poll_interval_sec` | Seconds between two market scans | 5 / 5 / 5 / 120 |
| `notify.repeat_min` | An opportunity (same machine, same price) is reported again only after N minutes | `60` |
| `miner.type` | PRL miner on new machines: `peakminer` or `krig`. Change one machine with `/miner <platform> <id> krig`. | `peakminer` |

### 6.3. Renting (`rent.*`)

| Key | Meaning | Default |
|---|---|---|
| `rent.enabled` | Rent new machines (`/pause` and `/resume` switch it). Machines already rented stay watched either way. | `true` |
| `rent.max_machines` | Most machines rented at the same time on this platform | 1 / 100 / 5 / 5 |
| `rent.max_price_hour` | Price cap per machine in $/hour, everything included (`null` = no cap) | `null` |
| `rent.min_balance_hours` (Vast, Clore, QuickPod) | Rent only while the account balance still pays N hours of everything rented plus the new machine | 1 / 2 / 2 / – |
| `rent.manual_ban_hours` | After `/stop <platform> <id>` without a duration, that machine (Salad: that GPU class) is not rented again for N hours | 24 |
| `rent.coins.PRL` / `rent.coins.QTC` | Coins allowed when renting. Each machine is priced for both coins and mines the one that pays more; QTC also needs `qtc.enabled`. Both `false` = no renting. | `true` / `true` |

### 6.4. Profit thresholds (`profit.*`, `monitor.*`)

There are two thresholds per coin: one to **rent** a machine, a lower one to **give it back**. The gap keeps the bot from renting and returning the same machine over and over.

| Key | Meaning | Default |
|---|---|---|
| `profit.min_profit_by_coin.PRL` | Rent for PRL only when the estimated profit is at least this | `0.05` |
| `profit.min_profit_by_coin.QTC` | Rent for QTC only when the estimated profit is at least this (QTC moves more, so it is higher) | `0.10` |
| `monitor.min_profit_by_coin.PRL` | Give a PRL machine back when its **measured** profit stays under this for `monitor.low_profit_min` minutes. Must not be above the renting threshold. | `0.0` |
| `monitor.min_profit_by_coin.QTC` | Same for QTC | `0.03` |
| `monitor.low_profit_min` | Minutes under the give-back threshold before the machine is given back | `30` |

Before giving a machine back for low profit, the bot first tries to switch it to the other coin (if that coin clears its renting threshold), and on Salad to a cheaper priority.

### 6.5. Watching rented machines (`monitor.*`)

| Key | Meaning | Default |
|---|---|---|
| `monitor.interval_sec` | Seconds between two checks of each rented machine | 300 / 180 / 180 / 180 |
| `monitor.ready_timeout_sec` | A machine whose miner is not running after N seconds is given back and banned | 900 / 300 / 600 / 1200 |
| `monitor.warmup_sec` | Grace time after the start before the hashrate is judged | 300 / 2100 / 300 / 300 |
| `monitor.early_min` | A machine younger than N minutes is judged on its first reading after warm-up (a loss gives it back or switches its coin at once); older machines are judged on the averaging window | `60` |
| `monitor.window_min` | Hashrate = median of the last N minutes of miner readings | `15` |
| `monitor.min_hashrate_ratio` | A machine below this share of its expected hashrate (0.6 = 60%) is given back and banned (Salad: moved to another node) | `0.6` |
| `monitor.miner_down_checks` (Vast, QuickPod, Salad) | Checks in a row with the miner not running before the machine is given back (the miner restarts itself in between) | 2 / – / 2 / 3 |

### 6.6. Machine filters (`filters.*`)

| Key | Meaning | Default |
|---|---|---|
| `filters.min_reliability` (Vast, Clore, QuickPod) | Minimum reliability score the platform gives the machine (0–1) | `0.95` |
| `filters.min_cuda` (Vast, Clore, QuickPod) | Minimum CUDA version of the host driver; older drivers cannot run the miner | `12.9` |
| `filters.countries_exclude` (Vast, Clore, QuickPod) | Skip machines in these countries (2-letter codes). China often blocks GitHub and Docker Hub, so the miner cannot be downloaded. | `[CN]` |
| `filters.max_gpus` (Vast, Clore, QuickPod) | Skip machines with more GPUs than this | `8` |
| `filters.weak_ban_days` (Clore, QuickPod) | A machine that did not mine, had no SSH, or hashed far too low is banned for N days | `30` |

### 6.7. Second coin and coin switching (`qtc.*`)

| Key | Meaning | Default |
|---|---|---|
| `qtc.enabled` | Mine QTC on this platform (needs `QTC_WALLET`). Off: PRL only. | false / false / false / true |
| `qtc.miner` | Miner used for QTC | `peakminer` |
| `qtc.auto_switch` | Switch a machine that **still makes a profit** to the other coin when that coin clearly pays more | `false` |
| `qtc.switch_revenue_pct` (Vast, Clore, QuickPod) | With `auto_switch`: switch when the other coin earns at least this much more revenue (0.05 = 5%), both ways. `null` = use `switch_margin_pct` instead. | `0.05` |
| `qtc.switch_margin_pct` | When `switch_revenue_pct` is `null`, and for low-profit switches: the other coin must beat the current one by this many profit points | `0.05` |
| `qtc.switch_confirm_min` | The other coin must stay better for N minutes in a row before a switch | `60` |
| `qtc.switch_min_hold_h` | A machine keeps a coin at least N hours before it may switch again | `6` |
| `qtc.switch_back_ban_h` | If the new coin measures worse than the old one, the machine switches back and that coin is not tried again on it for N hours | `24` |
| `qtc.rent_avg_hours` (Vast; applies to every platform) | Rent for QTC on the lower of the 60-minute and the N-hour average revenue, so a short spike does not rent machines that lose once it fades. `0` = off. | `6` |

### 6.8. Vast only

| Key | Meaning | Default |
|---|---|---|
| `modes` | Rental types to scan: `ondemand` (fixed price) and/or `interruptible` (you bid; cheaper, but the machine stops when someone outbids you) | `[ondemand]` |
| `rent.prefer` | `profit`: rent the most profitable machine whatever its type. `mode`: follow `rent.mode_priority`. | `profit` |
| `rent.mode_priority` | Rental types allowed, in order of preference | `[ondemand, interruptible]` |
| `profit.min_profit_by_mode.ondemand` / `.interruptible` | Renting threshold per rental type. The higher of this and the coin's threshold applies. | `0.05` / `0.50` |
| `bid.margin_pct` | Bid this much above the minimum bid. When outbid, the bot bids again only if the machine still clears the interruptible threshold, else gives it back. | `0.05` |
| `filters.verified_only` | Rent only machines Vast marked as verified | `false` |
| `filters.whole_machine_only` | Rent only all the GPUs of a machine, never a part of it | `true` |
| `filters.min_compute_cap` | Minimum GPU compute capability (800 = RTX 30 series / A100 and newer) | `800` |
| `filters.host_fault_ban_days` | A machine that cannot start a container because of its owner's setup is banned for N days; an owner with 2 such machines has all of them banned | `30` |
| `filters.fallback_miner`, `filters.fallback_min_cuda` | Miner for hosts whose driver is too old for the main miner (`""` = skip those hosts), and the CUDA version it needs | `""`, `12.0` |
| `instance.disk_gb` | Disk rented with the machine, in GB (billed even while an interruptible machine is stopped) | `10` |

### 6.9. Clore only

| Key | Meaning | Default |
|---|---|---|
| `filters.min_power_ratio` | Skip servers whose GPU power limit is under this share of the GPU's full power; the expected speed is scaled by it | `0.7` |
| `filters.min_mrl_hours` | Skip servers whose maximum rental length is under N hours | `6` |
| `monitor.warmup_miner_sec` | Grace time when the bot reads the miner over SSH | `300` |
| `monitor.share_stall_min` | No share on the pool for N minutes = the miner is down | `30` |

On Clore, `monitor.warmup_sec` (2100 s) is the grace time when the bot has no SSH and watches the pool's 30-minute average instead.

### 6.10. QuickPod only

| Key | Meaning | Default |
|---|---|---|
| `filters.min_duration_days` | Skip machines whose maximum rental length is under N days | `1` |
| `instance.disk_gb` | Disk per pod in GB; machines offering less are skipped | `32` |
| `instance.bandwidth_gb_day` | Estimated traffic per pod per day, added to the cost | `0.5` |
| `monitor.ssh_fail_checks` | Checks in a row without SSH before the pod is given back | `4` |
| `monitor.no_hash_checks` | Checks in a row with the miner running but no readable hashrate before the pod is given back | `5` |

### 6.11. Salad only

On Salad you do not pick a machine: you pick a **GPU class** and a **priority** (`high` > `medium` > `low` > `batch`; higher costs more and is interrupted less), and Salad assigns a node. Waiting for a node is free; you pay only while it runs. SaladCloud has no balance API: keep credit on the portal and cap the spend with `rent.max_spend_hour`.

| Key | Meaning | Default |
|---|---|---|
| `rent.priorities` | Priorities allowed. The highest one that still clears the renting threshold is used. | `[high, medium, low, batch]` |
| `rent.max_per_class` | Most machines of the same GPU class | `3` |
| `rent.max_spend_hour` | Most dollars per hour for everything rented on Salad | `1.0` |
| `priority.up_confirm_min`, `priority.up_margin_pct` | Move a running machine up to a higher priority when it clears the renting threshold plus this margin for N minutes in a row | `30`, `0.03` |
| `priority.min_hold_min` | Keep a priority at least N minutes before moving up | `60` |
| `filters.class_ban_hours` | Ban a class at that priority for N hours after `max_reallocs` weak nodes in a row (`0` = no ban: delete and rent again) | `0` |
| `filters.alloc_fail_ban_hours` | Ban a class at that priority for N hours when no node came (`0` = no ban) | `0` |
| `instance.cpu`, `instance.memory_mb`, `instance.storage_gb` | Resources per machine: vCPUs, RAM in MB, disk in GB | `2`, `8192`, `10` |
| `instance.hash_factor` | Expected speed on a class never measured = table speed × this (Salad nodes are home PCs) | `0.8` |
| `monitor.wait_step_up_min` | Waiting for a node longer than N minutes moves the request up to the next priority that still pays | `10` |
| `monitor.max_down_min` | A running machine interrupted for more than N minutes in a row is given back | `90` |
| `monitor.max_reallocs` | A weak node is swapped for another one at most N times | `3` |

On Salad, `monitor.ready_timeout_sec` (1200 s) is the total wait for a node before the request is given up.

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
