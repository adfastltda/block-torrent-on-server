#!/bin/bash
#
# Rollback script for undoing torrent traffic block
# Removes iptables/nftables rules, cleans /etc/hosts, and deletes cron jobs
# Author: sam nikzad (rollback version)

echo "Starting rollback of torrent traffic block..."

# STEP 1: Remove iptables rules
echo "Removing iptables rules..."
if [ -f /etc/trackers ]; then
    sort /etc/trackers | uniq | while read -r domain; do
        if [ -n "$domain" ]; then
            # Resolve domain to IP addresses
            for ip in $(getent ahosts "$domain" | awk '{print $1}'); do
                iptables -D INPUT -d "$ip" -j DROP 2>/dev/null
                iptables -D FORWARD -d "$ip" -j DROP 2>/dev/null
                iptables -D OUTPUT -d "$ip" -j DROP 2>/dev/null
            done
        fi
    done
    echo "iptables rules cleanup attempted."
else
    echo "No /etc/trackers file found. Skipping iptables cleanup."
fi

# STEP 2: Remove nftables rules
if command -v nft &> /dev/null && nft list tables | grep -q 'torrentblock'; then
    echo "Removing nftables rules..."
    nft delete table inet torrentblock
    echo "nftables rules removed."
fi

# STEP 3: Clean /etc/hosts
echo "Cleaning /etc/hosts from tracker entries..."
if [ -f /etc/hosts.backup-torrentblock ]; then
    echo "Restoring /etc/hosts from backup."
    mv /etc/hosts.backup-torrentblock /etc/hosts
else
    echo "No backup found. Attempting to clean /etc/hosts manually."
    # As a fallback, fetch the list and remove entries.
    curl -s -L https://raw.githubusercontent.com/nikzad-avasam/block-torrent-on-server/main/Thosts -o /tmp/Thosts.tmp
    if [ -f /tmp/Thosts.tmp ]; then
        cp /etc/hosts /etc/hosts.backup.$(date +%F_%H-%M-%S)
        # Use grep to remove the blocked entries from /etc/hosts
        # We need to convert the Thosts file to a pattern file for grep
        awk '{print $2}' /tmp/Thosts.tmp > /tmp/Thosts.patterns
        grep -v -f /tmp/Thosts.patterns /etc/hosts > /etc/hosts.new && mv /etc/hosts.new /etc/hosts
        rm /tmp/Thosts.tmp /tmp/Thosts.patterns
        echo "/etc/hosts cleaned."
    else
        echo "Could not download Thosts file. Skipping /etc/hosts cleanup."
    fi
fi


# STEP 4: Remove cron jobs
if [ -f /etc/cron.daily/denypublic ]; then
    echo "Removing iptables cron job..."
    rm -f /etc/cron.daily/denypublic
    echo "iptables cron job removed."
else
    echo "No iptables cron job found."
fi

if [ -f /etc/cron.daily/nft-torrent-block ]; then
    echo "Removing nftables cron job..."
    rm -f /etc/cron.daily/nft-torrent-block
    echo "nftables cron job removed."
fi

# STEP 5: Optional - Clean up /etc/trackers file
echo "Removing /etc/trackers file..."
rm -f /etc/trackers

echo "Rollback completed successfully."