# Connects a Windows computer to the college's server, then runs the rest of the setup from the private repo.
# This file is public and holds no secrets: a computer gets no access until a person approved in the Telegram bot adds it.
# Safe to run again.
& {
$Server  = '157.180.80.24'
$HostKey = 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF6T1lYuPI2YmkaUxstN20hoXKSwSoOYzMz40ap/QfxA'
$Bot     = 'Tsamha_bot'
$OpenSsh = 'C:\Windows\System32\OpenSSH'
$Ssh     = "$OpenSsh\ssh.exe"
$SshDir  = "$HOME\.ssh"
$Key     = "$SshDir\id_tsamha"
$Name    = ($env:COMPUTERNAME.ToLower() -replace '[^a-z0-9._-]', '-')

function Connected { & $Ssh -o BatchMode=yes -o ConnectTimeout=15 tzama true 2>$null; $LASTEXITCODE -eq 0 }

if (-not (Test-Path $Ssh)) { Write-Host 'OpenSSH is missing. Add it under Settings > System > Optional features, then run this again.' -ForegroundColor Red; return }
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { Write-Host 'winget is missing. Install "App Installer" from the Microsoft Store, then run this again.' -ForegroundColor Red; return }

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host 'Installing Git...'
    winget install --id Git.Git -e --silent --source winget --accept-package-agreements --accept-source-agreements
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Write-Host 'Git did not install. Open a new PowerShell window and run this again.' -ForegroundColor Red; return }
}

New-Item -ItemType Directory -Force $SshDir | Out-Null

$newKey = -not (Test-Path $Key)
if ($newKey) {
    Write-Host "`nCreating this computer's key. Choose a passphrase: if the computer is lost, it protects the server."
    & "$OpenSsh\ssh-keygen.exe" -t ed25519 -f $Key -C $Name
    if (-not (Test-Path "$Key.pub")) { Write-Host 'The key was not created.' -ForegroundColor Red; return }
}

# The agent remembers the passphrase, so it is asked once and Claude's tools can connect. Windows asks for approval here.
$agent = Get-Service ssh-agent
if ($agent.StartType -ne 'Automatic' -or $agent.Status -ne 'Running') {
    Start-Process powershell -Verb RunAs -Wait -ArgumentList '-NoProfile', '-Command', 'Set-Service ssh-agent -StartupType Automatic; Start-Service ssh-agent'
}
& "$OpenSsh\ssh-add.exe" $Key

$config = "$SshDir\config"
if (-not ((Test-Path $config) -and (Select-String -Path $config -Pattern '^\s*Host\s+tzama\s*$' -Quiet))) {
    Add-Content -Path $config -Encoding ascii -Value "Host tzama`n    HostName $Server`n    User claude`n    IdentityFile ~/.ssh/id_tsamha`n    IdentitiesOnly yes"
}
$known = "$SshDir\known_hosts"
if (-not ((Test-Path $known) -and (Select-String -Path $known -SimpleMatch "$Server $HostKey" -Quiet))) {
    Add-Content -Path $known -Encoding ascii -Value "$Server $HostKey"
}

# Waits for Enter rather than polling: repeated refused logins get this address banned by fail2ban.
if ($newKey -or -not (Connected)) {
    $type, $b64 = (Get-Content "$Key.pub" -Raw).Trim() -split '\s+'
    Set-Clipboard "/addpc $Name $type $b64"
    Write-Host "`nA line for the bot is now on the clipboard. Paste and send it to @$Bot in Telegram." -ForegroundColor Cyan
    Write-Host "Check that the bot shows this same fingerprint:"
    & "$OpenSsh\ssh-keygen.exe" -lf "$Key.pub"
    Start-Process "https://t.me/$Bot"
    $tries = 0
    do {
        if ($tries -eq 3) { Write-Host 'Still not approved after 3 tries. Check /listpc in the bot, then run this again.' -ForegroundColor Red; return }
        Read-Host 'After the bot confirms, press Enter'
        $tries++
    } until (Connected)
}
Write-Host 'Connected to the server.' -ForegroundColor Green

# OneDrive can corrupt git folders, so a redirected Desktop is not used.
$desktop = [Environment]::GetFolderPath('Desktop')
$Root = if ($desktop -match 'OneDrive') { "$HOME\projects" } else { "$desktop\projects" }
New-Item -ItemType Directory -Force $Root | Out-Null
$repo = "$Root\tsamha-agents"
if (-not (Test-Path "$repo\.git")) {
    git clone -c core.autocrlf=false -c "core.sshCommand=$($Ssh -replace '\\', '/')" tzama:/srv/git/tsamha-agents.git $repo
    if ($LASTEXITCODE -ne 0) { Write-Host 'Could not copy the repo.' -ForegroundColor Red; return }
} else {
    git -C $repo pull -q --ff-only
}
powershell -NoProfile -ExecutionPolicy Bypass -File "$repo\tools\pc_setup\setup_local.ps1" -Root $Root
}
