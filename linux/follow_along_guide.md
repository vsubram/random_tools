# Settting up SFTP for multiple users to access a common SFTP location on Linux
For this tutorial, I am using the lastest Ubuntu image from Ubuntu Docker image repository.
I have used Dockers for this tutorial for ease of use. You can still replicate these steps with any Linux environment that supports Debian flavors.

## SFTP Creation

### Step 1: Create SFTP User Group
Create a new SFTP Users Group. Replace <b>sftp_users</b> with your desired group name.

```bash
$ sudo addgroup sftp_users
```

### Step 2: Create a SFTP user
Create a new SFTP User. Replace <b>acemine</b>, <b>syamelux</b> with your desired user names.

```bash
$ sudo adduser acemine
```
Add the username's Full Name, Password, if you are trying to follow these steps manually on a Linux box or machine.

Repeat the same for the other user too.

```bash
$ sudo adduser syamelux
```


### Step 3: Add the user to the SFTP group.
Add the users created in <b>Step 2</b> to the user group which was created in <b>Step 1</b>. 

```bash
$ sudo usermod -G sftp_users acemine
$ sudo usermod -G sftp_users syamelux
```

### Step 4: Create the a common directory which needs to be accessed by both users

Taken from: <a href = "https://www.tecmint.com/restrict-ssh-user-to-directory-using-chrooted-jail"> Restrict SSH User Access to Certain Directory Using Chrooted Jail </a>

Change root (chroot) in Unix-like systems such as Linux, is a means of separating specific user operations from the rest of the Linux system; changes the apparent root directory for the current running user process and its child process with new root directory called a chrooted jail.

Create the directories which will be used for SFTP collaboration.

```bash
$ sudo mkdir -p /opt/pentaho/test/Snapshot_Excelfiles
$ sudo chown root:root /opt/pentaho/test
```

Ensure to change ownership to the directory level above the shared directory, in this case, <b>Snapshot_Excelfiles</b> will be excluded.

```bash
$ sudo chown root:root /opt/pentaho/test
```

### Step 5: Assign ownership and permissions to directories
Ensure that ssers and groups have <b>read</b> and <b>write</b> access to the respective directories.

```bash
$ sudo chmod -R 755 /opt/pentaho/test/
```

Change ownership on directory <b>Snapshot_Excelfiles</b>, assigned to user <b>syamelux</b> which was previously created in <b>Step 2</b>.

```bash
$ sudo chown -R syamelux:syamelux /opt/pentaho/test/Snapshot_Excelfiles
```

### Step 6: Assign permissions to the group

The below commands will ensure that <b>sftp_users</b> can <b>read, write,</b> and <b>execute</b> within <b>Snapshot_Excelfiles</b> directory.
```bash
$ sudo chgrp sftp_users /opt/pentaho/test/Snapshot_Excelfiles
$ sudo chmod ug+rwX /opt/pentaho/test/Snapshot_Excelfiles
```

### Setp 7: Configure SFTP daemon and service

With the sftp group and user accounts created, enable SFTP in the main SSH configuration file.

Using an editor of your choice, open the file /etc/ssh/sshd_config.

```bash
$ sudo vim /etc/ssh/sshd_config
```

```bash
# update to only allow sftp and not ssh tunneling to limit the non-necessary activity
Match Group sftp_users
    ForceCommand internal-sftp
    PasswordAuthentication yes 
    ChrootDirectory /opt/pentaho/test
    PermitTunnel no
    AllowAgentForwarding no
    AllowTcpForwarding no
    X11Forwarding no
```

Save and close the file.

Below are the functions for each of the above configuration lines:

<li>Match Group <b>sftp_users</b>: Match the user group sftp_users.</li>
<li>ChrootDirectory <b>/opt/pentaho/test</b>: Restrict access to directories within the user's home directory.</li>
<li>PasswordAuthentication <b>yes</b>: Enable password authentication.</li>
<li>AllowTcpForwarding <b>no</b>: Disable TCP forwarding.</li>
<li>X11Forwarding <b>no</b>: Don't permit Graphical displays.</li>
<li>ForceCommand <b>internal-sftp</b>: Enable SFTP only with no shell access.</li>

<br>Also, confirm if SFTP is enabled (it is by default). The line below should be uncommented in <b>/etc/ssh/sshd_config</b>:</br>

```bash
# override default of no subsystems
Subsystem sftp  /usr/lib/openssh/sftp-server
```

Restart the SSH server for changes to take effect.

```bash
$ sudo systemctl restart sshd
```

## Testing SFTP Setup
Open a new terminal window and log in with sftp using a valid user account and password.

```bash
$ sftp acemine@SERVER-IP
```

OR

```bash
$ sftp acemine@127.0.01 
```

(If running within the same server SSH session)
List files within the directory. Your output should be similar to the one below:

```bash
$ acemine@127.0.0.1's password: 

Connected to 127.0.0.1.

sftp> ls

Snapshot_Excelfiles  

sftp>
```

Also, try creating a new directory within the subdirectory to test user permissions.

```bash
sftp> cd Snapshot_Excelfiles
sftp> mkdir uploads
sftp> ls
uploads 
```

## References:
<ol>
<li> <a href = "https://www.tecmint.com/restrict-ssh-user-to-directory-using-chrooted-jail/">Restrict SSH User Access to Certain Directory Using Chrooted Jail</a> </li>
<li> <a href = "https://medium.com/@lejiend7/create-sftp-container-using-docker-e6f099762e42"> Create SFTP Container using Docker - You may need Medium membership!!</li>
<li> <a href = "https://www.vultr.com/docs/setup-sftp-user-accounts-on-ubuntu-20-04/"> Setup SFTP User Accounts on Ubuntu 20.04</li>
<li> <a href = "https://goteleport.com/blog/shell-access-docker-container-with-ssh-and-docker-exec/"> SSH into Docker Container or Use Docker Exec? </li>
<li> <a href = "https://www.howtogeek.com/50787/add-a-user-to-a-group-or-second-group-on-linux/"> Add a User to a Group (or Second Group) on Linux </li>
<li> <a href = "https://linuxize.com/post/how-to-add-user-to-sudoers-in-ubuntu/"> How to Add User to Sudoers in Ubuntu </li>
<li> <a href = "https://askubuntu.com/questions/261663/how-can-i-set-up-sftp-with-chrooted-groups"> How can I set up SFTP with chrooted groups? </li>
</ol>