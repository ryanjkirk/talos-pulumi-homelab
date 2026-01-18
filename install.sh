image="https://factory.talos.dev/image/ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515/v1.12.1/metal-amd64.qcow2"
disk_size="10G"

# image info
# https://factory.talos.dev/?arch=amd64&bootloader=auto&cmdline-set=true&extensions=-&extensions=siderolabs%2Fqemu-guest-agent&platform=metal&target=metal&version=1.12.1

wget $image
sudo mv metal-amd64.qcow2 /var/lib/libvirt/images/
sudo qemu-img resize /var/lib/libvirt/images/metal-amd64.qcow2 $disk_size

# install talos
curl -sL https://talos.dev/install | sh

# install pulumi
curl -fsSL https://get.pulumi.com | sh

# configure pulumi for libvirt
pulumi config set libvirt:uri qemu:///system
pip install pulumi-libvirt
pip install --user pulumiverse-talos

# initialize
pulumi login --local
pulumi up
