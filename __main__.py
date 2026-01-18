import pulumi
import pulumi_libvirt as libvirt
import yaml

with open("cluster-config.yaml") as f:
    config = yaml.safe_load(f)

cluster_name = config["cluster_name"]
talos_image = config["talos_image"]
pool = config["pool"]
network = config["network"]
node_types = config["node_types"]

def create_node(name, memory, vcpu):
    vol = libvirt.Volume(f"{name}-vol",
        pool=pool,
        source=talos_image,
        format="qcow2")
    
    vm = libvirt.Domain(name,
        memory=memory,
        vcpu=vcpu,
        cpu=libvirt.DomainCpuArgs(
            mode="host-passthrough"
        ),
        disks=[libvirt.DomainDiskArgs(volume_id=vol.id)],
        network_interfaces=[libvirt.DomainNetworkInterfaceArgs(
            network_name=network,
            wait_for_lease=True
        )])
    
    return vm

for node_type, config in node_types.items():
    for i in range(1, config["count"] + 1):
        name = f"{cluster_name}-{node_type}{i:02d}"
        vm = create_node(name, config["memory"], config["vcpu"])
        pulumi.export(f"{node_type}{i:02d}_ip", vm.network_interfaces[0].addresses[0])
