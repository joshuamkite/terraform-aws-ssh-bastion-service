#cloud-config
---
package_update: true
packages:
  - python-pip

write_files:
  -
    content: |
       FROM ubuntu:16.04

        RUN apt-get update && apt-get install -y openssh-server sudo awscli && echo '\033[1;31mI am a one-time Ubuntu container with passwordless sudo. \033[1;37;41mI will terminate after 12 hours or else on exit\033[0m' > /etc/motd && mkdir /var/run/sshd

        EXPOSE 22
        CMD ["/opt/ssh_populate.sh"]
    path: /opt/sshd_worker/Dockerfile

  -
    content: |
        #!/bin/bash
        KST=(`aws sts assume-role --role-arn "${assume_role_arn}" --role-session-name $(hostname) --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' --output text`)
        export AWS_ACCESS_KEY_ID=${KST[0]}; export AWS_SECRET_ACCESS_KEY=${KST[1]}; export AWS_SESSION_TOKEN=${KST[2]}
        (
        count=1
        /opt/iam-authorized-keys-command | while read line
        do
          username=$( echo $line | sed -e 's/^# //' -e 's/+/plus/' -e 's/=/equal/' -e 's/,/comma/' -e 's/@/at/' )
          useradd -m -s /bin/bash -k /etc/skel $username
          usermod -a -G sudo $username
          echo $username\ 'ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/$count
          chmod 0440 /etc/sudoers.d/$count
          count=$(( $count + 1 ))
          mkdir /home/$username/.ssh
          read line2
          echo $line2 >> /home/$username/.ssh/authorized_keys
          chown -R $username:$username /home/$username/.ssh
          chmod 700 /home/$username/.ssh
          chmod 0600 /home/$username/.ssh/authorized_keys
        done

        ) > /dev/null 2>&1

        /usr/sbin/sshd -i
    path: /opt/iam_helper/ssh_populate.sh
    permissions: '0754'

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

  -
    content: |
        ${authorized_command_code}
    path: /opt/golang/src/iam-authorized-keys-command/main.go
    permissions: '0754'

  -
    content: |
        #!/bin/bash
        #debian specific set up for docker https://docs.docker.com/install/linux/docker-ce/debian/#install-using-the-repository
        sudo apt install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common
        curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | sudo apt-key add -
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") $(lsb_release -cs) stable"
        sudo apt update
        sudo apt install -y docker-ce
        sudo  pip install awscli
        #set host sshd to run on port 2222 and restart service
        sed -i 's/#Port[[:blank:]]22/Port\ 2222/'  /etc/ssh/sshd_config
        systemctl restart sshd.service
        systemctl enable sshd_worker.socket
        systemctl start sshd_worker.socket
        systemctl daemon-reload
        #Build sshd service container
        cd /opt/sshd_worker
        systemctl start docker
        docker build -t sshd_worker .
        mkdir /opt/iam_helper

        # build iam-authorized-keys-command
        sudo apt-get install -y golang
        export GOPATH=/opt/golang

        COMMAND_DIR=$GOPATH/src/iam-authorized-keys-command

        mkdir -p $COMMAND_DIR
        cd $COMMAND_DIR

        go get ./...
        go build -ldflags "-X main.iamGroup=${bastion_allowed_iam_group}" -o /opt/iam_helper/iam-authorized-keys-command ./main.go

        chown root /opt/iam_helper
        chmod -R 700 /opt/iam_helper
        #set hostname to match dns
        hostname -b ${bastion_host_name}-${vpc}-bastion-host
        echo ${bastion_host_name}-bastion-host > /etc/hostname
        echo '127.0.0.1 ${bastion_host_name}-bastion-host' | sudo tee --append /etc/hosts
    path: /var/lib/cloud/scripts/per-once/localinstall.sh
    permissions: '0754'

    