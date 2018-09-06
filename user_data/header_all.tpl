#cloud-config
---

write_files:

  -
    content: |
        [Unit]
        Description=SSH Socket for Per-Connection docker ssh container

        [Socket]
        ListenStream=22
        Accept=true

        [Install]
        WantedBy=sockets.target
    path: /etc/systemd/system/sshd_worker.socket

  -
    content: |
        [Unit]
        Description=SSH Per-Connection docker ssh container

        [Service]
        Type=simple
        ExecStart= /usr/bin/docker run --rm -i --hostname ${bastion_host_name}_%i -v /dev/log:/dev/log -v /opt/iam_helper:/opt:ro sshd_worker
        StandardInput=socket
        RuntimeMaxSec=43200

        [Install]
        WantedBy=multi-user.target
    path: /etc/systemd/system/sshd_worker@.service