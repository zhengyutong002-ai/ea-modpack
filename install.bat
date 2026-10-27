@echo off
rem Ea x Rising Legends 2 installer. The installer body (PowerShell) is below the ##PS1 line.
setlocal
set "EA_SELF=%~f0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$t=[IO.File]::ReadAllText($env:EA_SELF,[Text.Encoding]::UTF8); $f=Join-Path $env:TEMP 'ea-installer.ps1'; [IO.File]::WriteAllText($f,$t.Substring($t.IndexOf('##'+'PS1')),(New-Object Text.UTF8Encoding $true)); & powershell -NoProfile -ExecutionPolicy Bypass -File $f"
echo.
pause
exit /b

##PS1 ---- 乖離剣エア インストーラー本体（install.bat から呼ばれます） ----
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Host.UI.RawUI.WindowTitle = '乖離剣エア インストーラー'

$PackUrl    = 'https://raw.githubusercontent.com/zhengyutong002-ai/ea-modpack/main/pack.toml'
$BootUrl    = 'https://github.com/packwiz/packwiz-installer-bootstrap/releases/latest/download/packwiz-installer-bootstrap.jar'
$RL2Version = 'qNcvkPw3'   # Modrinth の Rising Legends 2 1.2
$InstName   = 'Rising Legends 2'
$MemoryMB   = 6144
$UA         = 'ea-modpack-installer (github.com/zhengyutong002-ai/ea-modpack)'
$Total      = 5
$script:Cur = ''

$Prism = Join-Path $env:APPDATA 'PrismLauncher'
$Inst  = Join-Path $Prism "instances\$InstName"
$MC    = Join-Path $Inst 'minecraft'
$Tmp   = Join-Path $env:TEMP 'ea-install'

function Say($text, $color = 'Gray') { Write-Host "   $text" -ForegroundColor $color }
function Step($n, $text) {
    $script:Cur = "[$n/$Total] $text"
    Write-Host ''
    Write-Host "  $script:Cur" -ForegroundColor Cyan
}
function Footer { Write-Host ''; Write-Host '                                        Made with Claude' -ForegroundColor DarkGray }
function Save($path, $text) { [IO.File]::WriteAllText($path, $text, (New-Object Text.UTF8Encoding $false)) }
# ファイル名に [ ] ' ( ) や空白があるので、パスはすべて .NET / -LiteralPath で扱う（ワイルドカード扱いを避ける）
function Make-Dir($path) { [void][IO.Directory]::CreateDirectory($path) }
function Exists($path) { [IO.File]::Exists($path) }
function Sha1($path) { (Get-FileHash -LiteralPath $path -Algorithm SHA1).Hash.ToLower() }
# 一時ファイルにダウンロードしてから改名。失敗したら 3 回までやり直す
function Get-File($url, $path, $sha1 = $null) {
    Make-Dir ([IO.Path]::GetDirectoryName($path))
    $part = "$path.part"
    $last = $null
    foreach ($try in 1..3) {
        try {
            if (Exists $part) { [IO.File]::Delete($part) }
            $wc = New-Object Net.WebClient
            $wc.Headers.Add('User-Agent', $UA)
            try { $wc.DownloadFile([Uri]$url, $part) } finally { $wc.Dispose() }
            if ($sha1 -and (Sha1 $part) -ne $sha1) { throw 'ファイルが壊れています（ハッシュ不一致）' }
            if (Exists $path) { [IO.File]::Delete($path) }
            [IO.File]::Move($part, $path)
            return
        } catch {
            $last = $_.Exception.Message
            Start-Sleep -Seconds (2 * $try)
        }
    }
    if (Exists $part) { [IO.File]::Delete($part) }
    throw "$([IO.Path]::GetFileName($path)) をダウンロードできませんでした（3 回失敗：$last）"
}
function Find-Prism {
    foreach ($p in @("$env:LOCALAPPDATA\Programs\PrismLauncher\prismlauncher.exe",
                     "$env:ProgramFiles\PrismLauncher\prismlauncher.exe",
                     "${env:ProgramFiles(x86)}\PrismLauncher\prismlauncher.exe")) {
        if ($p -and (Exists $p)) { return $p }
    }
    return $null
}

Write-Host ''
Write-Host '  ────────────────────────────────────────' -ForegroundColor DarkCyan
Write-Host '    乖離剣エア インストーラー' -ForegroundColor White
Write-Host '    Rising Legends 2 ＋ 乖離剣エア' -ForegroundColor Gray
Write-Host '  ────────────────────────────────────────' -ForegroundColor DarkCyan
Say 'こんにちは！ゲームに必要なものを順番に準備します。'
Say '回線によって 10〜30 分ほどかかります。このウィンドウは閉じずにお待ちください。'

try {
    while (Get-Process prismlauncher -ErrorAction SilentlyContinue) {
        Write-Host ''
        Say 'Prism Launcher が開いています。閉じてから Enter キーを押してください。' 'Yellow'
        [void](Read-Host)
    }
    Make-Dir $Tmp

    # 1. Prism Launcher
    Step 1 'Prism Launcher を準備中…'
    if (Find-Prism) {
        Say 'すでにインストールされています。'
    } else {
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Say 'winget でインストールしています…'
            & winget install --id PrismLauncher.PrismLauncher -e --source winget --silent --accept-source-agreements --accept-package-agreements | Out-Null
        }
        if (-not (Find-Prism)) {
            Say '公式サイト（GitHub）からインストーラーをダウンロードしています…'
            $rel = Invoke-RestMethod 'https://api.github.com/repos/PrismLauncher/PrismLauncher/releases/latest' -UserAgent $UA
            $asset = $rel.assets | Where-Object { $_.name -match 'Windows-MSVC-Setup.*\.exe$' -and $_.name -notmatch 'arm64' } | Select-Object -First 1
            if (-not $asset) { throw 'Prism Launcher のインストーラーが見つかりませんでした。' }
            $setup = Join-Path $Tmp $asset.name
            Get-File $asset.browser_download_url $setup
            Start-Process $setup -ArgumentList '/S' -Wait
        }
        if (-not (Find-Prism)) { throw 'Prism Launcher をインストールできませんでした。' }
        Say 'インストールしました。'
    }

    # 2. Rising Legends 2 1.2
    Step 2 'Rising Legends 2 をダウンロード中…'
    $ver = Invoke-RestMethod "https://api.modrinth.com/v2/version/$RL2Version" -UserAgent $UA
    $pf = $ver.files | Where-Object { $_.primary } | Select-Object -First 1
    if (-not $pf) { $pf = $ver.files[0] }
    $zip = Join-Path $Tmp 'rl2.zip'
    Get-File $pf.url $zip $pf.hashes.sha1
    $pack = Join-Path $Tmp 'rl2'
    if ([IO.Directory]::Exists($pack)) { [IO.Directory]::Delete($pack, $true) }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [IO.Compression.ZipFile]::ExtractToDirectory($zip, $pack)
    $index = [IO.File]::ReadAllText((Join-Path $pack 'modrinth.index.json'), [Text.Encoding]::UTF8) | ConvertFrom-Json
    Say "$($index.name) を取得しました。"

    # 3. モッド（Modrinth から直接ダウンロード）
    $files = @($index.files | Where-Object { -not $_.env -or $_.env.client -ne 'unsupported' })
    Step 3 "モッドをダウンロード中…（全 $($files.Count) 個）"
    Make-Dir $MC
    $i = 0
    foreach ($f in $files) {
        $i++
        Write-Host -NoNewline "`r   $i / $($files.Count)   "
        if ($f.path -match '\.\.' -or [IO.Path]::IsPathRooted($f.path)) { continue }
        $dest = [IO.Path]::Combine($MC, $f.path.Replace('/', '\'))
        if ((Exists $dest) -and (Sha1 $dest) -eq $f.hashes.sha1) { continue }
        Get-File $f.downloads[0] $dest $f.hashes.sha1   # index の URL はエンコード済み（%5B など）
    }
    Write-Host ''
    foreach ($dir in 'overrides', 'client-overrides') {
        $src = Join-Path $pack $dir
        if (-not [IO.Directory]::Exists($src)) { continue }
        foreach ($file in [IO.Directory]::GetFiles($src, '*', 'AllDirectories')) {
            $rel = $file.Substring($src.Length + 1)
            $dest = [IO.Path]::Combine($MC, $rel)
            if ($rel -eq 'options.txt' -and (Exists $dest)) { continue }   # 2 回目以降はゲーム設定を残す
            Make-Dir ([IO.Path]::GetDirectoryName($dest))
            [IO.File]::Copy($file, $dest, $true)
        }
    }
    Make-Dir (Join-Path $Inst 'mrpack')
    [IO.File]::Copy((Join-Path $pack 'modrinth.index.json'), (Join-Path $Inst 'mrpack\modrinth.index.json'), $true)
    Say '完了しました。'

    # 4. 乖離剣エアの自動アップデートとメモリ
    Step 4 '乖離剣エアの自動アップデートとメモリ（6 GB）を設定中…'
    Get-File $BootUrl (Join-Path $MC 'packwiz-installer-bootstrap.jar')
    $mcv = $index.dependencies.minecraft
    $nfv = $index.dependencies.neoforge
    Save (Join-Path $Inst 'mmc-pack.json') @"
{
    "components": [
        { "uid": "net.minecraft", "version": "$mcv", "important": true },
        { "uid": "net.neoforged", "version": "$nfv" }
    ],
    "formatVersion": 1
}
"@
    $pre = '"\"$INST_JAVA\" -jar packwiz-installer-bootstrap.jar ' + $PackUrl + '"'
    Save (Join-Path $Inst 'instance.cfg') @"
[General]
ConfigVersion=1.3
InstanceType=OneSix
name=$InstName
iconKey=modrinth_rlcraft_2
ManagedPack=true
ManagedPackType=modrinth
ManagedPackID=R2PHNAyg
ManagedPackName=Rising Legends 2
ManagedPackVersionID=$RL2Version
ManagedPackVersionName=$($index.name)
OverrideCommands=true
PreLaunchCommand=$pre
OverrideMemory=true
MinMemAlloc=1024
MaxMemAlloc=$MemoryMB
"@
    Say '設定しました。'

    # 5. 後片付け
    Step 5 '後片付け中…'
    Remove-Item -LiteralPath $Tmp -Recurse -Force -ErrorAction SilentlyContinue
    Say 'OK'

    Write-Host ''
    Write-Host '  ────────────────────────────────────────' -ForegroundColor DarkCyan
    Write-Host '    インストール完了！' -ForegroundColor Green
    Write-Host '  ────────────────────────────────────────' -ForegroundColor DarkCyan
    Say '次にやること：' 'White'
    Say '1. スタートメニューから「Prism Launcher」を開く'
    Say '   （初回は設定画面が出ます。言語を選んで「次へ」、Java は自動ダウンロードで OK）'
    Say '2. 右上の「アカウント」から Microsoft アカウントでログイン'
    Say '   ※ Minecraft Java 版を購入したアカウントが必要です'
    Say '3. 「Rising Legends 2」をダブルクリックして起動'
    Write-Host ''
    Say '初回起動では Minecraft 1.21.1・NeoForge・乖離剣エアなどを自動でダウンロードするので、'
    Say 'しばらく時間がかかります。のんびり待っててね。'
    Footer
} catch {
    Write-Host ''
    Write-Host "  うまくいきませんでした：$script:Cur" -ForegroundColor Yellow
    Say "理由：$($_.Exception.Message)"
    Write-Host ''
    Say 'お手数ですが、この画面のスクリーンショットを撮って送ってください。' 'White'
    Say 'もう一度 install.bat を実行すると、続きからやり直せます。'
    Footer
    exit 1
}
