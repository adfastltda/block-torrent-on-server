
#!/bin/bash
#
# Credit to original author: sam https://github.com/nikzad-avasam/block-torrent-on-server
# GitHub:   https://github.com/nikzad-avasam/block-torrent-on-server
# Author:   sam nikzad

echo -n "Blocking all torrent trafic on your server. pls wait ... "
wget -q -O/etc/trackers https://raw.githubusercontent.com/nikzad-avasam/block-torrent-on-server/main/domains
cat >/etc/cron.daily/denypublic<<'EOF'
#!/bin/bash
# This script is created by btorrent.sh
# It blocks torrent traffic by adding iptables rules for each domain in /etc/trackers.

# Ensure the trackers file exists
if [ ! -f /etc/trackers ]; then
    exit 0
fi

# Read unique domains and add iptables rules
sort /etc/trackers | uniq | while read -r domain; do
    if [ -n "$domain" ]; then
        /sbin/iptables -D INPUT -d "$domain" -j DROP &>/dev/null
        /sbin/iptables -D FORWARD -d "$domain" -j DROP &>/dev/null
        /sbin/iptables -D OUTPUT -d "$domain" -j DROP &>/dev/null
        /sbin/iptables -A INPUT -d "$domain" -j DROP
        /sbin/iptables -A FORWARD -d "$domain" -j DROP
        /sbin/iptables -A OUTPUT -d "$domain" -j DROP
    fi
done
EOF
chmod +x /etc/cron.daily/denypublic
/etc/cron.daily/denypublic
curl -s -LO https://raw.githubusercontent.com/nikzad-avasam/block-torrent-on-server/main/Thosts
cat Thosts >> /etc/hosts
sort -uf /etc/hosts > /etc/hosts.uniq && mv /etc/hosts{.uniq,}
echo "${OK}"
