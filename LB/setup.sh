#!/bin/bash

apt update && apt install -y keepalived haproxy

APISERVER_VIP=192.168.132.100 #VIP of Load balancer
APISERVER_DEST_PORT=6443
network_interface="$(ls /sys/class/net | grep -v lo)"

MASTER_NODE1_NAME="master1"
MASTER_NODE2_NAME="master2"
MASTER_NODE3_NAME="master3"
MASTER_NODE1_ip="192.168.132.101"
MASTER_NODE3_ip="192.168.132.103"
MASTER_NODE2_ip="192.168.132.102"


cat >> /etc/keepalived/check_apiserver.sh <<EOF
#!/bin/sh

errorExit() {
    echo "*** $*" 1>&2
    exit 1
}

curl --silent --max-time 2 --insecure https://localhost:${APISERVER_DEST_PORT}/ -o /dev/null || errorExit "Error GET https://localhost:${APISERVER_DEST_PORT}/"
if ip addr | grep -q ${APISERVER_VIP}; then
    curl --silent --max-time 2 --insecure https://${APISERVER_VIP}:${APISERVER_DEST_PORT}/ -o /dev/null || errorExit "Error GET https://${APISERVER_VIP}:${APISERVER_DEST_PORT}/"
fi
EOF


chmod +x /etc/keepalived/check_apiserver.sh

cat >> /etc/keepalived/keepalived.conf <<EOF
vrrp_script check_apiserver {
  script "/etc/keepalived/check_apiserver.sh"
  interval 3
  timeout 10
  fall 5
  rise 2
  weight -2
}

vrrp_instance VI_1 {
    state BACKUP
    interface $network_interface
    virtual_router_id 1
    priority 100
    advert_int 5
    authentication {
        auth_type PASS
        auth_pass 234555
    }
    virtual_ipaddress {
        192.168.132.100
    }
    track_script {
        check_apiserver
    }
}
EOF

cat >> /etc/haproxy/haproxy.cfg <<EOF

frontend kubernetes-frontend
  bind *:6443
  mode tcp
  option tcplog
  default_backend kubernetes-backend

backend kubernetes-backend
  option httpchk GET /healthz
  http-check expect status 200
  mode tcp
  option ssl-hello-chk
  balance roundrobin
    server $MASTER_NODE1_NAME $MASTER_NODE1_ip:6443 cookie p1 check fall 3 rise 2 
    server $MASTER_NODE2_NAME $MASTER_NODE2_ip:6443 cookie p1 check fall 3 rise 2
    server $MASTER_NODE3_NAME $MASTER_NODE3_ip:6443 cookie p1 check fall 3 rise 2

EOF

systemctl enable --now keepalived
systemctl enable haproxy && systemctl restart haproxy 
systemctl status keepalived && systemctl status haproxy 