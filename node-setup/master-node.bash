#!/bin/bash

# Load necessary kernel modules for Kubernetes
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

# Load overlay and br_netfilter modules immediately
sudo modprobe overlay
sudo modprobe br_netfilter

# Setup sysctl parameters required by Kubernetes, ensuring they persist after reboot
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl parameters without needing a reboot
sudo sysctl --system

# Disable swap, which is a requirement for Kubernetes
sudo swapoff -a
# Ensure swap remains disabled after reboot
(crontab -l 2>/dev/null; echo "@reboot /sbin/swapoff -a") | crontab - || true

# Update system package index and install necessary dependencies
sudo apt-get update -y
sudo apt-get install -y software-properties-common gpg curl apt-transport-https ca-certificates

# Add the CRI-O repository to the system
curl -fsSL https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/Release.key |
    gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/ /" |
    tee /etc/apt/sources.list.d/cri-o.list

# Update package index again and install CRI-O (container runtime)
sudo apt-get update -y
sudo apt-get install -y cri-o

# Enable and start the CRI-O service
sudo systemctl daemon-reload
sudo systemctl enable crio --now
sudo systemctl start crio.service

# Download and install crictl tool for interacting with CRI-O
VERSION="v1.30.0"
wget https://github.com/kubernetes-sigs/cri-tools/releases/download/$VERSION/crictl-$VERSION-linux-amd64.tar.gz
sudo tar zxvf crictl-$VERSION-linux-amd64.tar.gz -C /usr/local/bin
rm -f crictl-$VERSION-linux-amd64.tar.gz

# Add the Kubernetes repository and keys for version 1.30
KUBERNETES_VERSION=1.30
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v$KUBERNETES_VERSION/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v$KUBERNETES_VERSION/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update package index and check available versions of kubeadm
sudo apt-get update -y
apt-cache madison kubeadm | tac

# Install kubelet, kubeadm, and kubectl
sudo apt-get install -y kubelet kubeadm kubectl

# Hold the Kubernetes packages at their current versions to prevent automatic updates
sudo apt-mark hold kubelet kubeadm kubectl

# Install jq for JSON processing
sudo apt-get install -y jq

# Retrieve the IP address of the node and set it in the kubelet configuration
network_interface="$(ls /sys/class/net | grep -v lo)"
local_ip="$(ip --json addr show $network_interface | jq -r '.[0].addr_info[] | select(.family == "inet") | .local')"
cat > /etc/default/kubelet << EOF
KUBELET_EXTRA_ARGS=--node-ip=$local_ip
EOF
# Set the environment variables for the IP address of the master node and Pod CIDR
IPADDR="$(ip --json addr show $network_interface | jq -r '.[0].addr_info[] | select(.family == "inet") | .local')"
NODENAME=$(hostname -s)
POD_CIDR="$(ip -o -f inet addr show $network_interface | awk '{print $4}' | sed 's/\.[0-9]*\//\.0\//')"

# Initialize the Kubernetes cluster with kubeadm, using the master node's IP address
# and specifying the Pod CIDR. Ignore swap preflight checks.
sudo kubeadm init --apiserver-advertise-address=$IPADDR \
                  --apiserver-cert-extra-sans=$IPADDR \
                  --pod-network-cidr=$POD_CIDR --node-name $NODENAME \
                  --ignore-preflight-errors Swap

# Init the HA Cluster
kubeadm init --control-plane-endpoint="192.168.132.100:6443" \ # VIP of your Load Balancer
                    --upload-certs  \
                    --apiserver-cert-extra-sans="192.168.132.100" \ # VIP of your Load Balancer
                    --pod-network-cidr=192.168.0.0/16 \
                    --ignore-preflight-errors Swap

export KUBECONFIG=/etc/kubernetes/admin.conf
kubectl config view --kubeconfig=/etc/kubernetes/admin.conf
kubectl --kubeconfig=/etc/kubernetes/admin.conf get nodes
curl -k https://192.168.132.100:6443/healthz


# Setup kubeconfig for the root user to access the cluster
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config


