#!/bin/bash
cat << EOF > /etc/systemd/system/sshd_worker.socket
[Unit]
Description=SSH Socket for Per-Connection docker ssh container

[Socket]
ListenStream=22
Accept=true

[Install]
WantedBy=sockets.target
EOF
cat << EOF > /etc/systemd/system/sshd_worker@.service
[Unit]
Description=SSH Per-Connection docker ssh container

[Service]
Type=simple
ExecStart= /usr/bin/docker run --rm -i --hostname ${bastion_host_name}_%i -v /dev/log:/dev/log -v /opt/iam_helper:/opt:ro sshd_worker
StandardInput=socket
RuntimeMaxSec=43200

[Install]
WantedBy=multi-user.target
EOF
#set host sshd to run on port 2222 and restart service
sed -i 's/#Port[[:blank:]]22/Port\ 2222/'  /etc/ssh/sshd_config
systemctl restart sshd.service
systemctl enable sshd_worker.socket
systemctl start sshd_worker.socket
systemctl daemon-reload

#set hostname to match dns
hostnamectl set-hostname ${bastion_host_name}-${vpc}-bastion-host