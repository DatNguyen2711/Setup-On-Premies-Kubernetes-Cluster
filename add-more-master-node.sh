#!/bin/bash

IP_ADDRESS=$(ip -4 addr show ens33 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')


CERT_UPLOAD=$(kubeadm init phase upload-certs --upload-certs)






kubeadm join ${MASTER_NODE_IP}:6443 --token abcdef.0123456789abcdef \
    --discovery-token-ca-cert-hash sha256:8f4b344c8d6a33c7b45e1b7a3d23c4e4fb6322a7bff9c4d1b7e68fd70d96f89a \
    --control-plane --certificate-key 8f374ae5453b7ae304bb9c4c4bfb2d8a4c634b6a933bfa5a5dfd4c2d6e4e8d12 \
    --apiserver-advertise-address=${ORTHER_MASTER_NODE_IP}
