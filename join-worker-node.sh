#!/bin/bash

# Kiểm tra xem script có chạy với quyền root hay không
if [ "$(id -u)" -ne 0 ]; then
  echo "Script này cần được chạy với quyền root"
  exit 1
fi

# Thông tin về master node
MASTER_IP="172.16.16.100"   # Địa chỉ IP của master node

# Tạo discovery token
DISCOVERY_TOKEN=$(kubeadm token create --print-join-command | awk '{print $5}')

# Tạo certificate hash
CERT_HASH=$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | \
  openssl rsa -pubin -outform der 2>/dev/null | \
  sha256sum | awk '{print $1}')

# Tạo certificate key
CERT_KEY=$(kubeadm init phase upload-certs --upload-certs | \
  awk '/Using certificate key:/ {print $4}')

# Lệnh join worker node vào cluster
echo "Đang kết nối worker node vào Kubernetes cluster tại $MASTER_IP..."
kubeadm join $MASTER_IP:6443 --token $DISCOVERY_TOKEN --discovery-token-ca-cert-hash sha256:$CERT_HASH --control-plane --certificate-key $CERT_KEY

# Kiểm tra kết quả của lệnh join
if [ $? -eq 0 ]; then
  echo "Worker node đã được thêm vào cluster thành công!"
else
  echo "Có lỗi xảy ra khi thêm worker node vào cluster."
  exit 1
fi

chmod +x join-worker.sh


