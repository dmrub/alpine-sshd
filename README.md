# alpine-sshd
alpine-sshd is a docker container for running OpenSSH server. Also it includes rsync tool for data transfer.

## Configuration
### Available Environment Variables

 - **OPENSSH_PORT**: Port of the sshd server, it must be accessible in the local network. Defaults to 22.
 - **OPENSSH_ROOT_PASSWORD**: The password of the root user. Set it only for debug purposes. When set to empty string password authentication for root is disabled.
 - **OPENSSH_ROOT_AUTHORIZED_KEYS**: Public keys for root user delimited by newline. Can be generated by ssh-keygen.
 - **OPENSSH_USER** The name of the login user. Defaults to ssh.
 - **OPENSSH_USERID** The numeric ID of the login user. Defaults to 1001.
 - **OPENSSH_GROUP** The primary group of the login user. Defaults to ssh.
 - **OPENSSH_GROUPID** The numeric ID of the primary group of the login user. Defaults to 1001.
 - **OPENSSH_PASSWORD** The password of the login user. If set to empty string password authentication for login user is disabled. Defaults to empty string.
 - **OPENSSH_AUTHORIZED_KEYS**: Public keys for login user delimited by newline. Can be generated by ssh-keygen.
 - **OPENSSH_SHELL** Shell of the login user. Defaults to /bin/bash.
 - **OPENSSH_HOME** The home directory of the login user. Defaults to /home/ssh.
 - **OPENSSH_RUN** Commands to run with '/bin/sh -c'. Defaults to empty string.
 - **OPENSSH_ALLOW_TCP_FORWARDING** Sets AllowTcpForwarding SSHD option for the login user. Defaults to remote.

## References

 * https://linux.die.net/man/5/sshd_config
