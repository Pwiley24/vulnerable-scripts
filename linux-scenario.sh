#!/bin/bash
# CyberPatriot Linux Incident Response Scenario - "Innovatech Dynamics Breach"
# Prepares a Linux VM with simulated compromise for CyberPatriot training.

set -e

systemctl stop unattended-upgrades 2>/dev/null || true
systemctl disable unattended-upgrades 2>/dev/null || true

# Create authorized users
useradd -m -s /bin/bash sysadmin
echo "sysadmin:Company2023!" | chpasswd

# Create backdoor user
useradd -m -s /bin/bash attacker1
echo "attacker1:password123" | chpasswd
usermod -aG sudo attacker1

# Install and misconfigure services
apt-get update
apt-get install -y openssh-server vsftpd apache2

# Helper: remove any existing line for a key, then append the desired value
set_conf() {  # usage: set_conf <file> <key> <value> [separator]
  local file="$1" key="$2" val="$3" sep="${4:-=}"
  sed -i "/^[[:space:]]*#\?[[:space:]]*${key}\b/d" "$file"
  echo "${key}${sep}${val}" >> "$file"
}

# --- sshd: weak settings ---
set_conf /etc/ssh/sshd_config PermitRootLogin yes " "
systemctl restart ssh

# --- vsftpd: weak settings ---
set_conf /etc/vsftpd.conf anonymous_enable YES
set_conf /etc/vsftpd.conf write_enable YES
set_conf /etc/vsftpd.conf anon_upload_enable YES
set_conf /etc/vsftpd.conf anon_mkdir_write_enable YES
set_conf /etc/vsftpd.conf ssl_enable NO
set_conf /etc/vsftpd.conf chroot_local_user NO
mkdir -p /srv/ftp
echo "internal use only - payroll_export.csv" > /srv/ftp/notes.txt
systemctl restart vsftpd

# --- Apache: weak settings ---
cat > /etc/apache2/conf-available/weak.conf <<'EOC'
ServerTokens Full
ServerSignature On
TraceEnable On
<Directory /var/www/html/backup>
    Options +Indexes
    Require all granted
</Directory>
EOC
a2enconf weak
mkdir -p /var/www/html/backup
echo "db_password=hunter2" > /var/www/html/backup/config.bak
apache2ctl configtest
systemctl restart apache2

# Add malicious cron job
echo "* * * * * root echo 'Hacked' > /tmp/hacked.txt" > /etc/cron.d/hacked

# Place scenario README on desktop
mkdir -p /home/sysadmin/Desktop
cat > /home/sysadmin/Desktop/README-Innovatech-Incident.txt <<EOF
Innovatech Dynamics Linux Breach Scenario

- Remove unauthorized users and cron jobs
- Harden SSH and services
- Secure the system per company policy
- Answer forensic questions in this file

Allowed Users:
sysadmin --> root/sudo permissions

Services:
ftp --> maintained by sysadmin
apache --> maintained by sysadmin
ssh

Login: sysadmin / Company2023!
EOF

chown sysadmin:sysadmin /home/sysadmin/Desktop/README-Innovatech-Incident.txt

echo "Linux VM setup complete. Take a snapshot now for CyberPatriot training."
