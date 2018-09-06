
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
        sudo apt install -y docker-ce python-pip
        sudo  pip install awscli
        #set host sshd to run on port 2222 and restart service
        sed -i 's/#Port[[:blank:]]22/Port\ 2222/'  /etc/ssh/sshd_config
        systemctl restart sshd.service
        systemctl enable sshd_worker.socket
        systemctl start sshd_worker.socket
        systemctl daemon-reload
        systemctl start docker
        #Build sshd service container
        ${container_build}
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
        hostnamectl set-hostname ${bastion_host_name}-${vpc}-bastion-host
    path: /var/lib/cloud/scripts/per-once/localinstall.sh
    permissions: '0754'