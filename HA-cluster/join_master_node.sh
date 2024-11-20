#!/bin/bash

#VIP of the load balancer
LB_VIP="10.0.0.1"

# IP of the node you want to join in the cluster
ORTHER_MASTER_NODE_IP="192.168.10.111"  

TOKEN=$(kubeadm token create)

CERT_UPLOAD=$(kubeadm init phase upload-certs --upload-certs | grep -oP '(?<=Using certificate key: )[a-f0-9]+')

CA_HASH=$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | \
          openssl rsa -pubin -outform DER 2>/dev/null | \
          openssl dgst -sha256 -hex | awk '{print $2}')

kubeadm join $LB_VIP:6443 --token $TOKEN \
    --discovery-token-ca-cert-hash sha256:$CA_HASH \
    --certificate-key $CERT_UPLOAD \
    --apiserver-advertise-address=$ORTHER_MASTER_NODE_IP \
    --control-plane 
