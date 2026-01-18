#!/bin/bash
set -e

# read counts from cluster-config.yaml
cluster_name=`grep "cluster_name:" cluster-config.yaml | awk '{print $2}'`
ctr_count=`grep -A1 "ctr:" cluster-config.yaml | grep "count:" | awk '{print $2}'`
wrk_count=`grep -A1 "wrk:" cluster-config.yaml | grep "count:" | awk '{print $2}'`

# get first control plane IP for cluster endpoint
control_plane_ip=`pulumi stack output ctr01_ip`

# check if we need to regenerate due to cert mismatch
if [ -f talosconfig ]; then
  echo "Testing existing certificates..."
  talosctl --talosconfig talosconfig config endpoint $control_plane_ip
  if ! talosctl --talosconfig talosconfig version --nodes $control_plane_ip --short &>/dev/null; then
    echo "Certificate mismatch detected - VMs were likely recreated"
    echo "Deleting old configs and regenerating..."
    rm -f controlplane.yaml worker.yaml talosconfig
  fi
fi

# generate configs if they don't exist
if [ ! -f controlplane.yaml ]; then
  echo "Generating Talos configs..."
  talosctl gen config $cluster_name https://$control_plane_ip:6443
  echo "Configuring talosctl endpoints..."
  talosctl --talosconfig talosconfig config endpoint $control_plane_ip
  talosctl config merge talosconfig
  use_insecure=true
else
  echo "Using existing configs, updating endpoints..."
  talosctl --talosconfig talosconfig config endpoint $control_plane_ip
  talosctl config merge talosconfig
  use_insecure=false
fi

# apply configs to control plane nodes
echo "Applying configs to control plane nodes..."
for i in `seq -f "%02g" 1 $ctr_count`; do
  ip=`pulumi stack output ctr${i}_ip`
  echo "  Configuring talos-ctr$i at $ip"
  
  if [ "$use_insecure" = true ]; then
    talosctl apply-config --insecure --nodes $ip --file controlplane.yaml
  else
    talosctl apply-config --nodes $ip --file controlplane.yaml
  fi
  
  echo "  Verifying:"
  for attempt in 1 2 3 4 5 6 7 8 9 10; do
    if talosctl version --nodes $ip --short 2>/dev/null; then
      break
    fi
    echo "    Waiting... (attempt $attempt/10)"
    sleep 3
  done
done

# apply configs to worker nodes
echo "Applying configs to worker nodes..."
for i in `seq -f "%02g" 1 $wrk_count`; do
  ip=`pulumi stack output wrk${i}_ip`
  echo "  Configuring talos-wrk$i at $ip"
  
  if [ "$use_insecure" = true ]; then
    talosctl apply-config --insecure --nodes $ip --file worker.yaml
  else
    talosctl apply-config --nodes $ip --file worker.yaml
  fi
  
  echo "  Verifying:"
  for attempt in 1 2 3 4 5 6 7 8 9 10; do
    if talosctl version --nodes $ip --short 2>/dev/null; then
      break
    fi
    echo "    Waiting... (attempt $attempt/10)"
    sleep 3
  done
done

echo ""
echo "Configuration complete. If this is first setup, bootstrap the cluster with:"
echo "  talosctl bootstrap --nodes $control_plane_ip"
echo ""
echo "Then check cluster health with:"
echo "  talosctl health --nodes $control_plane_ip"
echo ""
echo "Follow dmesg:"
echo "  talosctl dmesg --nodes $control_plane_ip --follow"
echo ""
echo "Get kubeconfig:"
echo '  talosctl kubeconfig --nodes `pulumi stack output ctr01_ip`'
echo ""
echo "After cluster is healthy, label worker nodes with:"
echo ""
echo "  kubectl get nodes -l '!node-role.kubernetes.io/control-plane' --no-headers -o custom-columns=NAME:.metadata.name | while read node; do"
echo "    kubectl label node \$node node-role.kubernetes.io/worker=worker --overwrite"
echo "  done"
echo ""
