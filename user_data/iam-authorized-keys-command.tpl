#!/bin/bash
mkdir -p /opt/golang/src/iam-authorized-keys-command/
cat << EOF > /opt/golang/src/iam-authorized-keys-command/main.go
        ${authorized_command_code}
EOF
DEBIAN_FRONTEND=noninteractive
sudo apt-get install -y golang
export GOPATH=/opt/golang

COMMAND_DIR=$GOPATH/src/iam-authorized-keys-command

mkdir -p $COMMAND_DIR
cd $COMMAND_DIR

go get ./...
go build -ldflags "-X main.iamGroup=${bastion_allowed_iam_group}" -o /opt/iam_helper/iam-authorized-keys-command ./main.go
