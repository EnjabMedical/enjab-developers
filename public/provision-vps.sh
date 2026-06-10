#!/usr/bin/env bash
#
# Enjab VPS provisioner. Run this on YOUR LAPTOP against a BRAND-NEW Hetzner Ubuntu VPS.
# It refuses to touch anything that is not a supported, dual-stack, Hetzner Ubuntu box, then
# hardens it: a key-only "server" sudo user, root + password SSH disabled, fail2ab, ufw,
# unattended security updates, and Docker. You never ssh in as root and "just start".
#
#   bash <(curl -fsSL https://developers.enjab.ae/provision-vps.sh)
#
set -euo pipefail

SUPPORTED_UBUNTU="22.04 24.04 26.04"   # LTS only
SERVER_USER="server"

# ---------- pretty ----------
if [ -t 1 ]; then B=$'\033[1;36m'; G=$'\033[1;32m'; Y=$'\033[1;33m'; R=$'\033[1;31m'; D=$'\033[2m'; N=$'\033[0m'; else B= G= Y= R= D= N=; fi
say()  { printf '%s==>%s %s\n' "$B" "$N" "$*"; }
ok()   { printf '%s  ok%s %s\n' "$G" "$N" "$*"; }
warn() { printf '%s   !%s %s\n' "$Y" "$N" "$*"; }
die()  { printf '%s   x%s %s\n' "$R" "$N" "$*" >&2; exit 1; }

printf '%s\n' "${B}Enjab VPS provisioner${N}"
printf '%s\n\n' "${D}Hardens a brand-new Hetzner Ubuntu VPS. Refuses anything that is not compliant.${N}"

command -v ssh >/dev/null || die "ssh is not installed on this machine."
# The root password is fed to ssh via SSH_ASKPASS_REQUIRE=force, which needs OpenSSH 8.4+.
sshv="$(ssh -V 2>&1 | sed -n 's/^OpenSSH_\([0-9][0-9]*\)\.\([0-9][0-9]*\).*/\1 \2/p')"
set -- $sshv; SMAJ="${1:-0}"; SMIN="${2:-0}"
if [ "$SMAJ" -lt 8 ] 2>/dev/null || { [ "$SMAJ" -eq 8 ] 2>/dev/null && [ "$SMIN" -lt 4 ] 2>/dev/null; }; then
  warn "OpenSSH ${SMAJ}.${SMIN} is older than 8.4; ssh may prompt you to re-type the root password."
fi

# ---------- 1. SSH key (the server becomes key-only, so you MUST have one) ----------
KEY_PRIV=""
for k in id_ed25519 id_ecdsa id_rsa; do
  [ -f "$HOME/.ssh/$k.pub" ] && { KEY_PRIV="$HOME/.ssh/$k"; break; }
done
if [ -z "$KEY_PRIV" ]; then
  warn "No SSH key found in ~/.ssh."
  printf 'Generate a new ed25519 key now? [Y/n] '; read -r a < /dev/tty || true
  case "${a:-Y}" in
    [Nn]*) die "An SSH key is required: the server is key-only after hardening." ;;
    *) ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519" -N "" -C "enjab-$(whoami)@$(hostname -s 2>/dev/null || echo laptop)" ; KEY_PRIV="$HOME/.ssh/id_ed25519" ;;
  esac
fi
PUBKEY="$(cat "$KEY_PRIV.pub")"
PUBKEY_B64="$(printf '%s' "$PUBKEY" | base64 | tr -d '\n')"
ok "Using key ${D}$KEY_PRIV.pub${N}"

# ---------- 2. prompts ----------
printf 'New VPS IP address (the IPv4 you ssh to): '; read -r IP < /dev/tty
[ -n "${IP:-}" ] || die "No IP given."
printf 'Root password (from Hetzner): '; read -rs ROOTPW < /dev/tty; printf '\n'
[ -n "${ROOTPW:-}" ] || die "No password given."

printf '\nAbout to pre-check and harden %s%s%s as a Hetzner Ubuntu VPS.\n' "$B" "$IP" "$N"
printf 'Continue? [y/N] '; read -r go < /dev/tty || true
case "${go:-N}" in [Yy]*) : ;; *) die "Aborted." ;; esac

# ---------- ssh helpers ----------
# Feed the root password without sshpass (OpenSSH 8.4+ honours SSH_ASKPASS_REQUIRE=force).
run_root() {
  local ap rc
  ap="$(mktemp)"; cat > "$ap" <<'SH'
#!/bin/sh
printf '%s\n' "$ENJAB_VPS_PW"
SH
  chmod 700 "$ap"
  ENJAB_VPS_PW="$ROOTPW" SSH_ASKPASS="$ap" SSH_ASKPASS_REQUIRE=force \
    ssh -T -o StrictHostKeyChecking=accept-new -o PreferredAuthentications=password \
        -o PubkeyAuthentication=no -o NumberOfPasswordPrompts=1 -o ConnectTimeout=20 \
        "root@$IP" "$@"
  rc=$?; rm -f "$ap"; return $rc
}
run_server() {
  ssh -T -i "$KEY_PRIV" -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new \
      -o BatchMode=yes -o ConnectTimeout=20 "$SERVER_USER@$IP" "$@"
}

# ---------- 3. the remote provisioning (pre-check, then install). NO lockout yet. ----------
PROVISION_REMOTE='
set -euo pipefail
SUPPORTED="22.04 24.04 26.04"
SERVER_USER="server"
PUBKEY="$(printf "%s" "${1:?missing key}" | base64 -d)"

echo "==> pre-checks"
. /etc/os-release
[ "${ID:-}" = "ubuntu" ] || { echo "REFUSE: OS is ${PRETTY_NAME:-unknown}, not Ubuntu."; exit 10; }
case " $SUPPORTED " in *" ${VERSION_ID:-} "*) : ;; *) echo "REFUSE: Ubuntu ${VERSION_ID:-?} is not a supported LTS ($SUPPORTED)."; exit 11 ;; esac
v4="$(ip -4 -o addr show scope global 2>/dev/null | awk "{print \$4}" | cut -d/ -f1 | grep -vE "^(10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.|169\.254\.|127\.|100\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])\.)" | head -1)"
[ -n "$v4" ] || { echo "REFUSE: no PUBLIC IPv4 address (found only private/none)."; exit 12; }
v6="$(ip -6 -o addr show scope global 2>/dev/null | awk "{print \$4}" | cut -d/ -f1 | grep -ivE "^(fe80|fc|fd|::1$)" | head -1)"
[ -n "$v6" ] || { echo "REFUSE: no PUBLIC IPv6 address (dual-stack with a global IPv6 is required)."; exit 13; }
HET=no
grep -rqi hetzner /sys/class/dmi/id/ 2>/dev/null && HET=yes
curl -fs --max-time 4 http://169.254.169.254/hetzner/v1/metadata/instance-id 2>/dev/null | grep -q . && HET=yes
[ "$HET" = yes ] || { echo "REFUSE: this does not look like a Hetzner server (DMI + cloud-metadata check failed)."; exit 14; }
echo "    ok: Ubuntu $VERSION_ID, dual-stack, Hetzner"

export DEBIAN_FRONTEND=noninteractive
mkdir -p /etc/needrestart/conf.d && printf "%s\n" "\$nrconf{restart} = \"a\";" > /etc/needrestart/conf.d/99-enjab.conf || true

echo "==> apt update + upgrade"
apt-get update -y
apt-get -y -o Dpkg::Options::="--force-confold" -o Dpkg::Options::="--force-confdef" upgrade
apt-get -y install ca-certificates curl gnupg ufw fail2ban unattended-upgrades apt-listchanges qemu-guest-agent
timedatectl set-timezone UTC 2>/dev/null || true

echo "==> user: $SERVER_USER"
id "$SERVER_USER" >/dev/null 2>&1 || useradd -m -s /bin/bash "$SERVER_USER"
usermod -aG sudo "$SERVER_USER"
install -d -m 700 -o "$SERVER_USER" -g "$SERVER_USER" "/home/$SERVER_USER/.ssh"
printf "%s\n" "$PUBKEY" > "/home/$SERVER_USER/.ssh/authorized_keys"
chmod 600 "/home/$SERVER_USER/.ssh/authorized_keys"; chown "$SERVER_USER:$SERVER_USER" "/home/$SERVER_USER/.ssh/authorized_keys"
passwd -l "$SERVER_USER" >/dev/null 2>&1 || true
printf "%s ALL=(ALL) NOPASSWD:ALL\n" "$SERVER_USER" > /etc/sudoers.d/90-enjab-server
chmod 440 /etc/sudoers.d/90-enjab-server
visudo -cf /etc/sudoers.d/90-enjab-server

echo "==> docker"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $VERSION_CODENAME stable" > /etc/apt/sources.list.d/docker.list
apt-get update -y
apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
usermod -aG docker "$SERVER_USER"
systemctl enable --now docker

echo "==> unattended-upgrades"
cat > /etc/apt/apt.conf.d/20auto-upgrades <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF
cat > /etc/apt/apt.conf.d/51enjab-unattended <<EOF
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "03:30";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
EOF
systemctl enable --now unattended-upgrades || echo "WARN: unattended-upgrades did not enable; auto security updates may be off"

echo "==> fail2ban"
cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 4
backend  = systemd
[sshd]
enabled = true
EOF
fail2ban-client -t || echo "WARN: fail2ban config test failed; the sshd jail may not load"
systemctl enable --now fail2ban

echo "==> sysctl hardening"
cat > /etc/sysctl.d/99-enjab-hardening.conf <<EOF
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
kernel.kptr_restrict = 2
EOF
sysctl -p /etc/sysctl.d/99-enjab-hardening.conf >/dev/null || echo "WARN: some sysctl hardening keys did not apply"

echo "==> firewall (ufw): deny in, allow ssh + 80 + 443"
ufw allow OpenSSH >/dev/null
ufw allow 80/tcp  >/dev/null
ufw allow 443/tcp >/dev/null
ufw default deny incoming  >/dev/null
ufw default allow outgoing >/dev/null
ufw --force enable >/dev/null

echo "==> ssh base hardening (root/password still ON until your key is verified)"
cat > /etc/ssh/sshd_config.d/00-enjab.conf <<EOF
PubkeyAuthentication yes
X11Forwarding no
AllowAgentForwarding no
MaxAuthTries 4
LoginGraceTime 30
ClientAliveInterval 300
ClientAliveCountMax 2
EOF
sshd -t && { systemctl reload ssh 2>/dev/null || systemctl reload sshd 2>/dev/null || true; }
echo "PROVISION_OK"
'

# ---------- 4. the lockdown (runs only AFTER the laptop proves the key works) ----------
LOCKDOWN_REMOTE='
set -euo pipefail
[ -s /home/server/.ssh/authorized_keys ] || { echo "REFUSE: server has no authorized_keys; not locking down."; exit 20; }
cat > /etc/ssh/sshd_config.d/00-enjab-lockdown.conf <<EOF
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
AllowUsers server
EOF
sshd -t
systemctl reload ssh 2>/dev/null || systemctl reload sshd 2>/dev/null || systemctl restart ssh
# Prove the merged, effective config actually disabled password + root login (sshd_config is
# first-match-wins, and our 00- drop-ins are read before any cloud-init file, but verify it).
EFF="$(sshd -T 2>/dev/null || true)"
if [ -n "$EFF" ]; then
  echo "$EFF" | grep -qi "^passwordauthentication no" || { echo "REFUSE: password auth is still enabled in the effective sshd config."; exit 21; }
  echo "$EFF" | grep -qi "^permitrootlogin no"        || { echo "REFUSE: root login is still enabled in the effective sshd config."; exit 22; }
else
  echo "WARN: could not read the effective sshd config to double-check the lockdown."
fi
echo "LOCKDOWN_OK"
'

# ---------- run it ----------
say "Pre-checking and provisioning $IP (a few minutes)..."
if ! printf '%s' "$PROVISION_REMOTE" | run_root "bash -s -- $PUBKEY_B64"; then
  die "Stopped. The server is not compliant or provisioning failed (see the REFUSE/error above). Nothing was locked down."
fi
ok "Provisioned."

say "Verifying you can log in as '$SERVER_USER' with your key (before any lockdown)..."
if [ "$(run_server 'sudo -n true 2>/dev/null && echo ENJAB_OK' 2>/dev/null || true)" != "ENJAB_OK" ]; then
  die "Could NOT log in as $SERVER_USER with $KEY_PRIV. Root + password SSH are still ON, so you are not locked out. Fix your key and re-run."
fi
ok "Key login + passwordless sudo confirmed."

say "Locking down SSH: disabling root login and password authentication..."
if ! printf '%s' "$LOCKDOWN_REMOTE" | run_server 'sudo bash -s'; then
  die "Lockdown failed. Investigate before trusting this server (root/password may still be enabled)."
fi
ok "Root login and password auth disabled."

say "Final re-check..."
if run_server 'true' 2>/dev/null; then ok "Still reachable as $SERVER_USER over your key."; else warn "Could not reconnect, check manually."; fi

printf '\n%sDone.%s %s is hardened.\n' "$G" "$N" "$IP"
printf 'Log in from now on with:  %sssh %s@%s%s\n' "$B" "$SERVER_USER" "$IP" "$N"
printf '%sRoot SSH and password login are OFF. Docker, fail2ban, ufw, and unattended security updates are ON.%s\n' "$D" "$N"
