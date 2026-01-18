# Talos via Pulumi

Local Kubernetes cluster using Talos Linux on KVM/libvirt, managed with Pulumi.

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
- `config-talos.sh` - Configures Talos nodes (applies configs, handles cert rotation)
- `troubleshoot-virsh.sh` - Debugging helper for virsh commands

### Generated Files (not committed)
- `controlplane.yaml` - Talos control plane node configuration
- `worker.yaml` - Talos worker node configuration
- `talosconfig` - Talos CLI authentication config

## Setup

`./install.sh`

Copy `sample-cluster-config.yaml` to `cluster-config.yaml` and edit as necessary.

## Usage

```bash
pulumi up
./config-talos.sh
```

## Notes

This uses the default network which is NAT. You may want to use your LAN DHCP. Additional configuration may be required.

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
