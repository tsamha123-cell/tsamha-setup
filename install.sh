#!/bin/bash
# Connects a Mac or Linux computer to the college's server and adds the "tsamha" command.
# This file is public and holds no secrets: a computer gets no access until a person approved in the Telegram bot adds it.
# Safe to run again. Smoove drafts and the picture tools are set up on Windows only.
set -eu
server=157.180.80.24
host_key='ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF6T1lYuPI2YmkaUxstN20hoXKSwSoOYzMz40ap/QfxA'
bot=Tsamha_bot
key=$HOME/.ssh/id_tsamha
name=$(hostname -s | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9._-]/-/g')

connected() { ssh -o BatchMode=yes -o ConnectTimeout=15 tzama true 2>/dev/null; }

mkdir -p "$HOME/.ssh"; chmod 700 "$HOME/.ssh"
new_key=0
if [ ! -f "$key" ]; then
  new_key=1
  echo "Creating this computer's key. Choose a passphrase: if the computer is lost, it protects the server."
  ssh-keygen -t ed25519 -f "$key" -C "$name"
fi
ssh-add "$key" 2>/dev/null || echo "Note: no ssh-agent here, so ssh will ask for the passphrase each time."

grep -qE '^\s*Host\s+tzama\s*$' "$HOME/.ssh/config" 2>/dev/null || printf 'Host tzama\n    HostName %s\n    User claude\n    IdentityFile ~/.ssh/id_tsamha\n    IdentitiesOnly yes\n' "$server" >> "$HOME/.ssh/config"
grep -qF "$server $host_key" "$HOME/.ssh/known_hosts" 2>/dev/null || echo "$server $host_key" >> "$HOME/.ssh/known_hosts"

# Waits for Enter rather than polling: repeated refused logins get this address banned by fail2ban.
if [ "$new_key" = 1 ] || ! connected; then
  echo
  echo "Send this line to @$bot in Telegram:"
  echo "/addpc $name $(cut -d' ' -f1,2 "$key.pub")"
  echo "Check that the bot shows this same fingerprint:"
  ssh-keygen -lf "$key.pub"
  tries=0
  while :; do
    [ "$tries" -lt 3 ] || { echo "Still not approved after 3 tries. Check /listpc in the bot, then run this again."; exit 1; }
    read -r -p 'After the bot confirms, press Enter ' _
    tries=$((tries + 1))
    connected && break
  done
fi
echo "Connected to the server."

mkdir -p "$HOME/.local/bin"
printf '#!/bin/sh\nexec ssh -t tzama tsamha-session\n' > "$HOME/.local/bin/tsamha"
chmod +x "$HOME/.local/bin/tsamha"
echo "Done. Type: tsamha  (if it is not found, add ~/.local/bin to PATH)"
