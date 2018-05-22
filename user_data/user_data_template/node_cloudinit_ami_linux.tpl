#cloud-config
---
package_update: true
packages:
  - python-pip

write_files:
  -
    content: |
        #!/bin/bash
        count=1
        /opt/iam_helper/iam-authorized-keys-command | while read line
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
    path: /opt/iam_helper/ssh_populate.sh
    permissions: '0754'

  -
    content: |
        ${authorized_command_code}
    path: /opt/golang/src/iam-authorized-keys-command/main.go
    permissions: '0754'

  -
    content: |
        #!/bin/bash
        mkdir /opt/iam_helper

        # build iam-authorized-keys-command
        sudo yum install -y golang
        export GOPATH=/opt/golang

        COMMAND_DIR=$GOPATH/src/iam-authorized-keys-command

        mkdir -p $COMMAND_DIR
        cd $COMMAND_DIR

        go get ./...
        go build -ldflags "-X main.iamGroup=${bastion_allowed_iam_group}" -o /opt/iam_helper/iam-authorized-keys-command ./main.go

        chown root /opt/iam_helper
        chmod -R 700 /opt/iam_helper

        /opt/iam_helper/ssh_populate.sh
        crontab -l | { cat; echo "*/15 * * * * /opt/iam_helper/ssh_populate.sh > /var/log/ssh_populate.log"; } | crontab -
    path: /var/lib/cloud/scripts/per-once/localinstall.sh
    permissions: '0754'


