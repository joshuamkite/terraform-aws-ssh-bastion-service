#cloud-config
---

write_files:

  -
    content: |
       FROM ubuntu:${container_ubuntu_version}

        RUN apt-get update && apt-get install -y openssh-server sudo awscli && echo '\033[1;31mI am a one-time Ubuntu container with passwordless sudo. \033[1;37;41mI will terminate after 12 hours or else on exit\033[0m' > /etc/motd && mkdir /var/run/sshd

        EXPOSE 22
        CMD ["/opt/ssh_populate.sh"]
    path: /opt/sshd_worker/Dockerfile