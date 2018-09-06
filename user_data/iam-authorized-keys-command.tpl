#!/bin/bash
mkdir -p /opt/golang/src/iam-authorized-keys-command/
cat << EOF > /opt/golang/src/iam-authorized-keys-command/main.go
        ${authorized_command_code}
EOF
chmod 0754 /opt/golang/src/iam-authorized-keys-command/main.go