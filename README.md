# snipGPU

Bot tự săn GPU giá rẻ trên **Vast.ai, Clore.ai, QuickPod và SaladCloud** để đào **PRL** (PearlHash) và **QTC** (Quantus) qua pool Kryptex. Bot làm các việc sau:

- quét giá liên tục, tính lãi từng máy theo doanh thu thật của pool;
- thuê máy khi lãi vượt ngưỡng bạn đặt, tự cài và chạy miner;
- đo hashrate thật, tự đổi sang coin lãi hơn (tuỳ chọn);
- trả máy khi lãi xuống thấp, miner lỗi hoặc hashrate yếu;
- báo cáo và nhận lệnh qua **Telegram**.

Bạn tải bản build ở mục **[Releases](../../releases/latest)**. Repo này chỉ chứa hướng dẫn và file mẫu, không có mã nguồn.

---

## ⚡ Cài nhanh 1 lệnh

Trước khi cài, chuẩn bị sẵn: **token bot Telegram**, **chat ID**, **ví PRL** và **API key** của nền tảng bạn dùng. Cách lấy từng thứ ở [mục 1](#1-chuẩn-bị).

**VPS / Linux.** Script tự cài Docker, hỏi từng thông tin, rồi chạy bot nền:

```bash
curl -fsSL https://raw.githubusercontent.com/jackerdev01/snipGPUs/main/install.sh | bash
```

**Windows.** Mở **PowerShell**, dán lệnh dưới. Script tải `snipgpu.exe`, hỏi từng thông tin, rồi chạy bot và cài để bot tự chạy khi bạn đăng nhập Windows:

```powershell
irm https://raw.githubusercontent.com/jackerdev01/snipGPUs/main/install.ps1 | iex
```

**Docker 1 dòng.** Thay các giá trị rồi chạy:

```bash
docker run -d --name snipgpu --restart unless-stopped -v ~/snipgpu/data:/data \
  -e TELEGRAM_BOT_TOKEN=123456:AAxxx -e TELEGRAM_CHAT_ID=123456789 \
  -e PRL_WALLET=prl1xxx -e VAST_API_KEY=xxx \
  ghcr.io/jackerdev01/snipgpu:latest
```

Muốn dùng nền tảng khác thì thêm `-e CLORE_API_KEY=...`, `-e QUICKPOD_API_KEY=...`, hoặc bộ `-e SALAD_API_KEY=... -e SALAD_ORG=... -e SALAD_PROJECT=...`. Thêm `-e QTC_WALLET=qz...` nếu đào QTC.

**File chạy thẳng, kiểu miner** (Windows `snipgpu.exe` / Linux `snipgpu-linux`):

```bash
./snipgpu --telegram-token 123456:AAxxx --chat-id 123456789 --prl-wallet prl1xxx --vast-key xxx
```

Các tham số khác: `--qtc-wallet`, `--clore-key`, `--quickpod-key`, `--salad-key`, `--salad-org`, `--salad-project`. Bot lưu chúng vào `data/.env`, nên **lần sau chỉ cần `./snipgpu`**, không phải gõ lại.

Chạy xong, Telegram sẽ nhận tin **"🤖 snipvast khởi động"**. Bot bắt đầu ở chế độ **chạy thử** (chỉ báo, không thuê). Xem [mục 4](#4-chạy-thử-rồi-bật-thuê-thật) để bật thuê thật.

> 🔒 Key gõ trực tiếp trên dòng lệnh sẽ nằm trong lịch sử shell. Script `install.sh` / `install.ps1` hỏi key thay vì bắt gõ trên lệnh, nên an toàn hơn. Nếu đã gõ key trên lệnh, xoá lịch sử bằng `history -c` (Linux).

Các phần dưới đây là hướng dẫn chi tiết và cách tuỳ chỉnh.

---

## Mục lục

1. [Chuẩn bị](#1-chuẩn-bị)
2. [Cài đặt: chọn 1 trong 3 cách](#2-cài-đặt)
   - [A. Docker trên VPS / Linux](#a-docker-trên-vps--linux-khuyên-dùng)
   - [B. Windows (file .exe)](#b-windows-file-exe)
   - [C. Linux không dùng Docker](#c-linux-không-dùng-docker)
3. [Điền cấu hình](#3-điền-cấu-hình)
4. [Chạy thử rồi bật thuê thật](#4-chạy-thử-rồi-bật-thuê-thật)
5. [Lệnh Telegram](#5-lệnh-telegram)
6. [Tuỳ chỉnh thường dùng](#6-tuỳ-chỉnh-thường-dùng)
7. [Cập nhật, sao lưu, chuyển máy](#7-cập-nhật-sao-lưu-chuyển-máy)
8. [Xử lý sự cố](#8-xử-lý-sự-cố)

---

## 1. Chuẩn bị

| Cần | Ghi chú |
|---|---|
| Một máy chạy 24/7 | VPS Linux 1 vCPU / 1 GB RAM là đủ, hoặc PC Windows bật liên tục. Máy này **không cần GPU**: bot chỉ thuê GPU ở các nền tảng. |
| Bot Telegram | Chat với [@BotFather](https://t.me/BotFather), gửi `/newbot` để nhận **token** dạng `123456789:AA...`. Sau đó **nhắn một tin bất kỳ cho bot vừa tạo**, nếu không bot sẽ không gửi tin cho bạn được. |
| Chat ID Telegram | Chat với [@userinfobot](https://t.me/userinfobot), nó trả lời `Id: 123456789`. |
| Ví PRL | Địa chỉ bắt đầu bằng `prl1...` |
| Ví QTC | Chỉ cần khi bạn bật đào QTC. Địa chỉ bắt đầu bằng `qz...` |
| Tài khoản và tiền nạp ở **ít nhất 1** nền tảng | Xem bảng bên dưới |

Lấy API key ở từng nền tảng:

| Nền tảng | Lấy key ở đâu | Ghi chú |
|---|---|---|
| **Vast.ai** | [cloud.vast.ai](https://cloud.vast.ai/) → Account → **API Keys** → Create | Nạp credit trước. |
| **Clore.ai** | [clore.ai](https://clore.ai/) → Profile → **API** | Nạp số dư USD (hoặc CLORE). |
| **QuickPod** | [console.quickpod.io](https://console.quickpod.io/) → Account → **API Key** | |
| **SaladCloud** | [portal.salad.com](https://portal.salad.com/) → Account → **API Access** | Cần thêm **tên organization** và **tên project**: tạo project trong portal, tên của chúng nằm trên URL `portal.salad.com/organizations/<org>/projects/<project>`. |

Nền tảng nào bạn không dùng thì bỏ qua.

---

## 2. Cài đặt

### A. Docker trên VPS / Linux (khuyên dùng)

**Bước 1. Cài Docker** (bỏ qua nếu máy đã có):

```bash
curl -fsSL https://get.docker.com | sh
```

**Bước 2. Tải file cấu hình chạy và khởi động lần đầu:**

```bash
mkdir -p ~/snipgpu && cd ~/snipgpu
curl -fsSLO https://raw.githubusercontent.com/jackerdev01/snipGPUs/main/docker-compose.yml
docker compose up -d
docker compose logs
```

Lần đầu bot tạo thư mục `~/snipgpu/data` với các file `.env`, `config_*.yaml` và `ssh/`, in ra danh sách những gì bạn cần điền, rồi tự thử lại sau ít giây.

**Bước 3.** Điền cấu hình theo [mục 3](#3-điền-cấu-hình):

```bash
nano data/.env
nano data/config_vast.yaml      # và các config_*.yaml của nền tảng bạn dùng
```

**Bước 4.** Khởi động lại rồi xem log:

```bash
docker compose restart
docker compose logs -f          # Ctrl+C để thoát xem log, bot vẫn chạy
```

Khi chạy được, Telegram sẽ nhận tin **"🤖 snipvast khởi động"**. Bot tự chạy lại khi VPS khởi động lại.

> **Windows có Docker Desktop** cũng làm y như trên trong PowerShell. Lệnh tải file ở bước 2 đổi thành:
> `curl.exe -fsSLO https://raw.githubusercontent.com/jackerdev01/snipGPUs/main/docker-compose.yml`

### B. Windows (file .exe)

1. Tải **[snipgpu.exe](../../releases/latest/download/snipgpu.exe)**.
2. Tạo thư mục riêng, ví dụ `C:\snipgpu\`, rồi chép `snipgpu.exe` vào đó.
3. **Chạy `snipgpu.exe`** (nhấp đúp). Lần đầu nó tạo thư mục `C:\snipgpu\data\`, liệt kê những gì còn thiếu, rồi chờ bạn nhấn Enter để đóng.
4. Mở `data\.env` và `data\config_*.yaml` bằng Notepad, rồi điền theo [mục 3](#3-điền-cấu-hình).
5. Chạy lại `snipgpu.exe`. Nếu bạn đóng cửa sổ console, bot cũng dừng theo.

Lưu ý:

- **Windows SmartScreen** có thể báo "Windows protected your PC" vì file chưa ký số. Bấm **More info → Run anyway**.
- Một số phần mềm diệt virus báo nhầm các file Python đã biên dịch. Nếu bị chặn, thêm thư mục `C:\snipgpu` vào danh sách loại trừ.
- **Tự chạy khi bật máy:** nhấn `Win+R`, gõ `shell:startup`, rồi tạo trong thư mục đó một shortcut trỏ tới `C:\snipgpu\snipgpu.exe`.
- Tắt chế độ **Sleep** của Windows. Máy ngủ thì bot cũng dừng, nhưng máy đã thuê vẫn tính tiền.

### C. Linux không dùng Docker

Bản build cần **Ubuntu 22.04+ / Debian 12+** (x86_64).

```bash
mkdir -p ~/snipgpu && cd ~/snipgpu
curl -fsSLo snipgpu https://github.com/jackerdev01/snipGPUs/releases/latest/download/snipgpu-linux
chmod +x snipgpu
./snipgpu            # lần đầu: tạo ./data rồi thoát
nano data/.env       # điền theo mục 3
./snipgpu            # chạy thử ở foreground, Ctrl+C để dừng
```

Để bot chạy nền và tự chạy lại khi reboot, tạo một service systemd:

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
journalctl -u snipgpu -f        # xem log
```

---

## 3. Điền cấu hình

Mọi thứ của bạn nằm trong thư mục **`data`**, ngay cạnh file chạy hoặc ở `~/snipgpu/data` nếu dùng Docker.

### 3.1. `data/.env`: key và Telegram

```ini
TELEGRAM_BOT_TOKEN=123456789:AAxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TELEGRAM_CHAT_ID=123456789

VAST_API_KEY=xxxxxxxx            # để trống = không dùng Vast
CLORE_API_KEY=
QUICKPOD_API_KEY=
SALAD_API_KEY=
SALAD_ORG=
SALAD_PROJECT=
```

- `TELEGRAM_BOT_TOKEN` và `TELEGRAM_CHAT_ID` là **bắt buộc**.
- Cần **ít nhất một** key nền tảng. Nền tảng nào để trống thì bot bỏ qua.
- Không đặt dấu nháy hay khoảng trắng quanh dấu `=`.

### 3.2. Ví đào

**Cách đơn giản nhất:** điền ví vào `data/.env`. Mỗi lần khởi động, bot tự ghi ví vào mọi file config:

```ini
PRL_WALLET=prl1qxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
QTC_WALLET=qzxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx      # chỉ cần khi đào QTC
```

Khi `PRL_WALLET` / `QTC_WALLET` có giá trị, chúng **luôn được ưu tiên** hơn ví ghi trong file config. Muốn đổi ví thì sửa ở `.env` rồi khởi động lại bot.

**Hoặc** điền tay trong từng file config. Mỗi nền tảng có một file riêng: `config_vast.yaml`, `config_clore.yaml`, `config_quickpod.yaml`, `config_salad.yaml`. Trong file của **mỗi nền tảng bạn dùng**, tìm các dòng:

```yaml
  wallet: ""   # BAT BUOC: dien dia chi vi cua ban
```

Rồi điền theo mục chứa dòng đó:

| Dòng `wallet:` nằm trong mục | Điền |
|---|---|
| `miner:` | Ví **PRL** (`prl1...`) |
| `qtc:` | Ví **QTC** (`qz...`). Chỉ bắt buộc khi `qtc.enabled: true` trong cùng file. |

Ví dụ:

```yaml
miner:
  wallet: "prl1qxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

Nếu còn thiếu ví hay key, bot **không khởi động** và in ra đúng dòng còn thiếu.

> File YAML phân biệt **thụt lề bằng dấu cách**. Chỉ sửa phần giá trị sau dấu `:`, đừng xoá khoảng trắng đầu dòng và đừng dùng phím Tab.

### 3.3. SSH key (bot tự lo)

Lần đầu chạy, bot tự tạo `data/ssh/id_ed25519` và gắn khoá này vào các máy nó thuê để đo hashrate và đổi coin. Bạn không cần làm gì. **Đừng xoá thư mục này** khi đang có máy thuê, vì bot sẽ mất quyền vào những máy đó.

---

## 4. Chạy thử rồi bật thuê thật

Mọi nền tảng bắt đầu ở chế độ **chạy thử** (`dry_run: true`): bot quét giá và **báo cơ hội lên Telegram** nhưng **không thuê và không tiêu tiền**.

Nên để chạy thử vài giờ để xem bot báo những máy nào và lãi ước tính bao nhiêu. Khi thấy ổn, bật thuê thật **từng nền tảng** qua Telegram:

| Nền tảng | Bật thuê thật | Về chạy thử |
|---|---|---|
| Vast | `/set vast dry_run false` | `/set vast dry_run true` |
| Clore | `/clore live` | `/clore dry` |
| QuickPod | `/quick live` | `/quick dry` |
| Salad | `/salad live` | `/salad dry` |

Bạn cũng có thể sửa `dry_run: false` trong file config rồi khởi động lại bot.

**Nên đặt giới hạn trước khi bật thuê thật**, ví dụ chỉ thuê 1 máy lúc đầu:

```
/set vast rent.max_machines 1
/set clore rent.max_machines 1
```

---

## 5. Lệnh Telegram

Gửi `/help` để xem đủ danh sách. Các lệnh hay dùng:

| Lệnh | Tác dụng |
|---|---|
| `/status` | Tình trạng bot, số dư, số máy đang thuê |
| `/report` | Báo cáo lãi/lỗ từng máy, so sánh 2 coin |
| `/pods` | Danh sách máy đang thuê |
| `/config` | Xem các thông số chính của mọi nền tảng |
| `/set <nền tảng> <khoá> <giá trị>` | Đổi thông số ngay, không cần khởi động lại. Ví dụ `/set vast rent.max_machines 2` |
| `/unset <nền tảng> <khoá>` | Trả thông số về giá trị trong file config |
| `/pause` / `/resume` | Tạm dừng / tiếp tục thuê máy mới trên mọi nền tảng (máy đang chạy vẫn được theo dõi). Thêm tên nền tảng để chỉ áp dụng cho nền tảng đó: `/pause clore` |
| `/stop <nền tảng> <id>` | Trả một máy ngay và không thuê lại máy đó trong 24 giờ |
| `/clore`, `/quick`, `/salad` | Tình trạng riêng từng nền tảng |
| `/bans` | Xem danh sách máy bị chặn |
| `/unban <nền tảng> machine <id>` | Gỡ chặn một máy |

`<nền tảng>` là một trong các tên `vast`, `clore`, `quick`, `salad`. Bot chỉ nhận lệnh từ đúng `TELEGRAM_CHAT_ID` của bạn, trong chat riêng với bot.

---

## 6. Tuỳ chỉnh thường dùng

Đổi qua Telegram bằng `/set <nền tảng> <khoá> <giá trị>` (có hiệu lực ngay, lưu ở `data/*_override.yaml`), hoặc sửa file `config_*.yaml` rồi khởi động lại bot. Mỗi nền tảng có bộ thông số riêng. Một số khoá chỉ có ở vài nền tảng: gửi `/config <nền tảng>` để xem đủ.

| Khoá | Ý nghĩa | Mặc định |
|---|---|---|
| `rent.max_machines` | Số máy thuê cùng lúc tối đa | 1 |
| `rent.max_price_hour` | Trần giá $/giờ cho cả máy (`null` = không giới hạn) | null |
| `rent.coins.PRL` / `rent.coins.QTC` | Cho phép thuê để đào coin đó | true |
| `profit.min_profit_by_coin.PRL` | Lãi tối thiểu để **thuê** máy đào PRL (0.05 = 5%) | 0.05 |
| `profit.min_profit_by_coin.QTC` | Lãi tối thiểu để **thuê** máy đào QTC | 0.10 |
| `monitor.min_profit_by_coin.PRL` | Lãi thực đo được dưới mức này kéo dài thì **trả máy** | 0.0 |
| `qtc.enabled` | Bật đào QTC (cần ví QTC) | tuỳ nền tảng |
| `qtc.auto_switch` | Tự đổi coin khi coin kia lãi hơn rõ | false |
| `filters.countries_exclude` | Bỏ qua máy ở các nước này | `[CN]` |
| `modes` (Vast) | `[ondemand]` (giá cố định) hoặc thêm `interruptible` (đấu giá, rẻ hơn nhưng có thể bị dừng) | `[ondemand]` |

Lãi được tính là `(doanh thu − chi phí) / chi phí`. Doanh thu lấy từ pool Kryptex theo giá coin hiện tại, đã trừ phí pool.

Ví dụ:

```
/set vast rent.max_machines 3
/set vast profit.min_profit_by_coin.PRL 0.10
/set clore qtc.enabled true
```

Ví và địa chỉ pool **không đổi được qua Telegram**. Lý do: nếu ai chiếm được chat Telegram, họ cũng không thể chuyển coin của bạn đi chỗ khác. Muốn đổi những mục này thì sửa file config rồi khởi động lại bot.

---

## 7. Cập nhật, sao lưu, chuyển máy

**Cập nhật bản mới.** Cấu hình trong `data` luôn được giữ nguyên.

- Docker: `docker compose pull && docker compose up -d`
- Windows / Linux: tải file mới ở [Releases](../../releases/latest), dừng bot, chép đè file chạy cũ, rồi chạy lại.

Khi có bản config mẫu mới, bot không ghi đè config của bạn. Nếu muốn lấy bản mẫu mới, đổi tên file cũ (ví dụ thành `config_vast.old.yaml`), chạy bot một lần để nó tạo file mới, rồi chép lại ví và các tuỳ chỉnh của bạn sang.

**Sao lưu / chuyển máy.** Chép nguyên thư mục `data` sang máy mới là đủ, vì nó chứa key, ví, SSH key và danh sách máy đang thuê. **Đừng chạy hai bot cùng một `data` và cùng token Telegram**, vì hai bot sẽ tranh nhau quản lý máy.

**Bảo mật.** `data/.env` và `data/ssh/` là bí mật, không gửi cho ai.

---

## 8. Xử lý sự cố

| Hiện tượng | Cách xử lý |
|---|---|
| Bot in "Can dien truoc khi chay" rồi dừng | Điền đúng các dòng được liệt kê, rồi chạy lại. |
| Telegram không nhận được tin | Kiểm tra token và chat ID, và chắc chắn bạn đã **nhắn cho bot trước** (bấm Start). |
| Log báo `HTTP 401` / `403` | API key sai, hoặc key đã bị xoá ở nền tảng. |
| Báo cơ hội nhưng không thuê | Đang chạy thử (`dry_run`), hết số dư, đạt `rent.max_machines`, hoặc đang `/pause`. Gửi `/status` để xem lý do. |
| Không có cơ hội nào | Thị trường không có máy đạt ngưỡng lãi. Có thể giảm `profit.min_profit_by_coin.*`, nhưng sẽ rủi ro hơn. |
| Máy thuê bị trả ngay sau vài phút | Máy không chạy được miner (driver cũ, mạng chặn GitHub) hoặc hashrate thấp. Bot tự chặn máy đó, đây là hành vi bình thường. |
| Docker: `permission denied` với thư mục `data` | Chạy `sudo chown -R $USER data`, hoặc chạy lệnh docker với `sudo`. |
| Windows: cửa sổ mở rồi tắt ngay | Mở `cmd`, `cd C:\snipgpu`, rồi chạy `snipgpu.exe` để đọc thông báo lỗi. |

Log của bot nằm ở `data/snipvast.log`, xoay vòng tối đa 3 file × 5 MB.

> ⚠️ **Rủi ro:** thuê GPU để đào coin có thể lỗ khi giá coin hoặc độ khó thay đổi. Bot chỉ thuê theo ngưỡng lãi bạn đặt và tự trả máy khi lỗ, nhưng không đảm bảo lợi nhuận. Hãy bắt đầu với số tiền nhỏ và theo dõi `/report`.
