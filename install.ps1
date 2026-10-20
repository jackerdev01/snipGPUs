# snipGPU - cai dat 1 lenh tren Windows (PowerShell):
#   irm https://raw.githubusercontent.com/jackerdev01/snipGPUs/main/install.ps1 | iex
# Tai snipgpu.exe ban moi nhat vao %USERPROFILE%\snipgpu, hoi token/key/vi (luu vao data\.env), tao shortcut tu chay
# khi dang nhap Windows, roi chay bot. Chay lai bat ky luc nao de cap nhat ban moi hoac doi key/vi.
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Dir = if ($env:SNIPGPU_DIR) { $env:SNIPGPU_DIR } else { Join-Path $env:USERPROFILE "snipgpu" }
$Exe = Join-Path $Dir "snipgpu.exe"
$EnvFile = Join-Path $Dir "data\.env"
$Url = "https://github.com/jackerdev01/snipGPUs/releases/latest/download/snipgpu.exe"

function Say($t) { Write-Host "==> $t" -ForegroundColor Green }

function Current($name) {
    if (Test-Path $EnvFile) {
        $line = Get-Content $EnvFile | Where-Object { $_ -match "^$name=" } | Select-Object -Last 1
        if ($line) { return $line.Substring($name.Length + 1) }
    }
    return ""
}

function Ask($name, $prompt, [switch]$Secret) {
    $def = Current $name
    $shown = if ($def -and $Secret) { $def.Substring(0, [Math]::Min(4, $def.Length)) + "..." } else { $def }
    $q = if ($shown) { "$prompt [$shown]" } else { $prompt }
    if ($Secret) {
        $s = Read-Host $q -AsSecureString
        $v = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($s))
    } else {
        $v = Read-Host $q
    }
    if ($v) { return $v.Trim() } else { return $def }
}

# 1. Dung ban dang chay (de ghi de file exe), tai ban moi
Get-Process snipgpu -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $Exe } | Stop-Process -Force
New-Item -ItemType Directory -Force (Join-Path $Dir "data") | Out-Null
Say "Tai snipgpu.exe ban moi nhat..."
Invoke-WebRequest $Url -OutFile $Exe -UseBasicParsing
Unblock-File $Exe

# 2. Hoi thong tin (Enter = giu gia tri trong ngoac)
Write-Host ""
Say "Nhap thong tin (Enter = giu gia tri trong ngoac, de trong = khong dung)"
$v = [ordered]@{}
$v["telegram-token"] = Ask TELEGRAM_BOT_TOKEN "Telegram bot token (tu @BotFather)" -Secret
$v["chat-id"]        = Ask TELEGRAM_CHAT_ID "Telegram chat ID (tu @userinfobot)"
$v["prl-wallet"]     = Ask PRL_WALLET "Vi PRL (prl1...)"
$v["qtc-wallet"]     = Ask QTC_WALLET "Vi QTC (qz..., Enter de bo qua)"
Write-Host "   Chua co tai khoan? Vast.ai:  https://cloud.vast.ai/?ref_id=716525"
Write-Host "                      Clore.ai: https://clore.ai/register?ref_id=6ph9tvyq"
Write-Host "                      QuickPod: https://console.quickpod.io?affiliate=303bbe95-4783-4a7d-ad33-98a8da2aec40"
$v["vast-key"]       = Ask VAST_API_KEY "Vast.ai API key" -Secret
$v["clore-key"]      = Ask CLORE_API_KEY "Clore.ai API key" -Secret
$v["quickpod-key"]   = Ask QUICKPOD_API_KEY "QuickPod API key" -Secret
$v["salad-key"]      = Ask SALAD_API_KEY "SaladCloud API key" -Secret
if ($v["salad-key"]) {
    $v["salad-org"]     = Ask SALAD_ORG "SaladCloud organization"
    $v["salad-project"] = Ask SALAD_PROJECT "SaladCloud project"
}

# 3. Bot luu vao data\.env, dien vi vao config, kiem tra du chua
$argv = @("--init")
foreach ($k in $v.Keys) { if ($v[$k]) { $argv += "--$k"; $argv += $v[$k] } }
Push-Location $Dir
& $Exe @argv
$code = $LASTEXITCODE
Pop-Location
if ($code -ne 0) { Write-Host "`nCon thieu thong tin o tren. Chay lai lenh cai dat de bo sung." -ForegroundColor Red; return }

# 4. Tu chay khi dang nhap Windows + chay ngay
$Startup = [Environment]::GetFolderPath("Startup")
$Shell = New-Object -ComObject WScript.Shell
$Lnk = $Shell.CreateShortcut((Join-Path $Startup "snipgpu.lnk"))
$Lnk.TargetPath = $Exe
$Lnk.WorkingDirectory = $Dir
$Lnk.Save()
Start-Process -FilePath $Exe -WorkingDirectory $Dir

Write-Host ""
Say "Xong. Bot dang chay trong cua so rieng (dong cua so = dung bot) va tu chay khi ban dang nhap Windows."
Write-Host "   Thu muc:   $Dir  (cau hinh: $Dir\data\config_*.yaml)"
Write-Host "   Telegram:  gui /status cho bot. Bot bat dau o che do CHAY THU (chi bao, khong thue)."
Write-Host "   Nho tat Sleep cua Windows: may ngu thi bot dung nhung may thue van tinh tien."
