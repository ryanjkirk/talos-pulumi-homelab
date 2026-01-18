function echorun {
    echo "=== $* ==="
    "$@"
}

function sv {
  sudo virsh "$@"
}         

vms=`sv list --all --name`
for vm in $vms; do
  # sv dumpxml $vm
  sv domifaddr $vm
  sv domdisplay $vm
  # sudo virt-viewer $vm
done

echorun sv vol-list default
# echorun sv net-dumpxml default
echorun sv net-dhcp-leases default
echorun sv list --all
echorun sv net-list --all
