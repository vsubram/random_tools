FROM ubuntu:latest

RUN apt-get update && apt-get install -y openssh-server

# configure sftp user
RUN useradd -rm -d /home/winsu99 -s /bin/bash -G sudo -u 10001 winsu99
RUN useradd -rm -d /home/syamelux -s /bin/bash -G sudo -u 10002 syamelux
RUN useradd -rm -d /home/acemine -s /bin/bash -G sudo -u 10003 acemine

# Testing PoC passwords - Not an approach to consider for production environments
RUN echo winsu99:Test123 | chpasswd
RUN echo syamelux:Test123 | chpasswd
RUN echo acemine:Test123 | chpasswd

# Create usergroup for SFTP users
RUN groupadd sftp_users
RUN usermod -a -G sftp_users syamelux
RUN usermod -a -G sftp_users acemine

# necessary sshd file
RUN mkdir /var/run/sshd

# SSH login fix (Keeping Session Alive). If not, user will be kicked off after ssh
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]

#setup directory for sftp
RUN mkdir -p /opt/pentaho/test/Snapshot_Excelfiles
RUN chown root:root /opt/pentaho/test

# Ensure that Users and groups have read, write and execute access to the respective directory
RUN chmod -R 755 /opt/pentaho/test/
RUN chown -R syamelux:syamelux /opt/pentaho/test/Snapshot_Excelfiles
# RUN chmod go-w /opt/pentaho/test/
RUN chgrp sftp_users /opt/pentaho/test/Snapshot_Excelfiles
RUN chmod ug+rwX /opt/pentaho/test/Snapshot_Excelfiles


# update to only allow sftp and not ssh tunneling to limit the non-necessary activity 
RUN echo '\n\
Match Group sftp_users \n\
ForceCommand internal-sftp \n\ 
PasswordAuthentication yes \n\ 
ChrootDirectory /opt/pentaho/test \n\ 
PermitTunnel no \n\ 
AllowAgentForwarding no \n\ 
AllowTcpForwarding no \n\ 
X11Forwarding no ' >> /etc/ssh/sshd_config