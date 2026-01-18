# Talos via Pulumi

Kubernetes cluster using Talos Linux on KVM/libvirt, managed by Pulumi via python.

## Prerequisites

- KVM/libvirt
- Python 3.x
- kubectl

# Installed by install.sh
- talos image
- Pulumi CLI
- talosctl

## Files

### Configuration
- `cluster-config.yaml` - Cluster configuration (node counts, resources, image path)
- `Pulumi.yaml` - Pulumi project definition

### Source Code
- `__main__.py` - Main Pulumi program (creates VMs with libvirt)

### Scripts
- `install.sh` - Initial setup script
- `configure-talos-cluster.sh` - Configure Talos nodes (applies configs, handles cert rotation)
- `generate-firewalld-rules.sh` - Allow remote access to these NAT'd VMs

### Generated Files
- `controlplane.yaml` - Talos control plane node configuration
- `worker.yaml` - Talos worker node configuration
- `talosconfig` - Talos CLI authentication config
- `Pulumi.<cluster-name>.yaml` - Pulumi stack configuration file

## Setup

Read `./install.sh` and change the image for your environment. This script is not designed for
various environemnts, is not idempotent, and should be run with care.

Copy `sample-cluster-config.yaml` to `cluster-config.yaml` and edit as necessary.

## Usage

```bash
pulumi up
./configure-talos-cluster.sh
```

## Notes

This uses the default network which is NAT. For this you will need to run the firewalld script.

You may want to use your LAN's DHCP and a bridge network instead.

```bash
cat > /tmp/macvtap-network.xml << 'EOF'
<network>
  <name>macvtap-net</name>
  <forward mode="bridge">
    <interface dev="wlo1"/>
  </forward>
</network>
EOF

sudo virsh net-define /tmp/macvtap-network.xml
sudo virsh net-start macvtap-net
sudo virsh net-autostart macvtap-net
```

Set your network to `macvtap-net`.

Additional configuration may be required.
