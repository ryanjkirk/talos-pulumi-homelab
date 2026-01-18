#!/bin/bash
set -e

# get IPs
server_ip=`ip -4 addr show wlo1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'`
control_plane_ip=`pulumi stack output ctr01_ip`

echo "Server IP: $server_ip"
echo "Control Plane IP: $control_plane_ip"
echo ""

# get zone for wlo1 interface
zone=`sudo firewall-cmd --get-zone-of-interface=wlo1 2>/dev/null || echo "public"`
echo "Using firewalld zone: $zone"
echo ""

# enable masquerading (required for NAT)
echo "Enabling masquerading..."
sudo firewall-cmd --zone=$zone --add-masquerade --permanent

# add port forward for kubernetes API
echo "Adding port forward for Kubernetes API (6443)..."
sudo firewall-cmd --zone=$zone --add-forward-port=port=6443:proto=tcp:toaddr=$control_plane_ip:toport=6443 --permanent

# add rich rule to allow forwarding to control plane
echo "Adding forward rule..."
sudo firewall-cmd --zone=$zone --add-rich-rule="rule family=ipv4 destination address=$control_plane_ip forward-port port=6443 protocol=tcp to-port=6443" --permanent

# reload to apply changes
echo "Reloading firewalld..."
sudo firewall-cmd --reload

echo ""
echo "firewalld rules applied and saved"
echo ""
echo "verify rules:"
echo "  sudo firewall-cmd --zone=$zone --list-all"
echo ""
