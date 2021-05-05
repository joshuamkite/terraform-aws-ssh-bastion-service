#!/bin/bash
mkdir -p /opt/iam_helper/
cat << 'EOF' > /opt/iam_helper/ssh_populate.sh
#!/bin/bash
KST=(`aws sts assume-role --role-arn "${assume_role_arn}" --role-session-name $(hostname) --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' --output text`)
export AWS_ACCESS_KEY_ID=$${KST[0]}; export AWS_SECRET_ACCESS_KEY=$${KST[1]}; export AWS_SESSION_TOKEN=$${KST[2]}
(
count=1
/opt/iam_helper/iam-authorized-keys-command | while read line
do
    username=$( echo $${line,,} | cut -d '@' -f 1 | sed -e 's/^# //' -e 's/+/plus/' -e 's/=/equal/' -e 's/,/comma/' -e 's/@/at/' )
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
EOF
chmod 0700 /opt/iam_helper/ssh_populate.sh
