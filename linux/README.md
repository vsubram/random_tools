# Settting up SFTP for multiple users to access a common SFTP location on Linux

I am using the lastest Ubuntu image from Ubuntu Docker image repository.
I have used Docker for this tutorial for ease of use. You can still replicate these steps with any Linux environment that supports Debian flavors.

## Problem Statement
In this exercise, I am trying to create a common SFTP directory, where multiple authorized users can read and write. The idea is to take this setup and apply it any Linux setting.

## Requirements
Before you start running the Dockerfile script, or following the steps to run on your local linux setup, you will need the following:

<ol>
<li>Docker Desktop or Linux Machine</li>
<li>Debian Flavor Linux: For example: Ubuntu 22.02</li>
<li>Familiarity with basic Linux commands.</li>
<li>A Terminal to connect and access files, directories and test. (For example: PuTTy on Windows, Terminal on Mac and Ubuntu)</li>
</ol>

## Running the docker script
Ensure that you have cloned/copied/downloaded the Dockerfile in your working directory, local onto your machine.

### Step 1: Build the image
Before building the image, replace the <YOUR_PASSWORD> with your password string.
I have used 3 random users for this exercise - <b>winsu99</b>, <b>syamelux</b>, <b>acemine</b>. You can change them in your copy of the Dockerfile if needed.

```Dockerfile
RUN echo winsu99:Test123 | chpasswd
```

Next run,

```bash
docker build -t <Image Name> .
```

Example:
```bash
docker build -t sftptest .
```

### Step 2: Run the image to create a docker container

```bash
docker run -d --name linux_sftp_test -p <any_free_host_port>:22 sftptest
```

Example:
```bash
docker run -d --name linux_sftp_test -p 2023:22 sftptest
```

### Step 3: Connect using SFTP

```bash
sftp -oPort=<assigned-port-from-previous-command> username@target_host
```

Example:
```bash
sftp -oPort=2023 acemine@127.0.0.1
```

