ARG ALPINE_VERSION=${ALPINE_VERSION:-3.9}
FROM alpine:${ALPINE_VERSION}

LABEL maintainer="https://github.com/dmrub"

ARG OPENSSH_VERSION=${OPENSSH_VERSION:-7.9_p1-r5}

ENV OPENSSH_VERSION=${OPENSSH_VERSION} \
    OPENSSH_PORT=22 \
    OPENSSH_ROOT_PASSWORD="" \
    OPENSSH_ROOT_AUTHORIZED_KEYS="" \
    OPENSSH_USER="ssh" \
    OPENSSH_USERID=1001 \
    OPENSSH_GROUP="ssh" \
    OPENSSH_GROUPID=1001 \
    OPENSSH_PASSWORD="" \
    OPENSSH_AUTHORIZED_KEYS="" \
    OPENSSH_HOME="/home/ssh" \
    OPENSSH_SHELL="/bin/bash" \
    OPENSSH_RUN="" \
    OPENSSH_ALLOW_TCP_FORWARDING="remote"

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN set -xe; \
    apk add --update --no-cache --virtual .build-deps \
        augeas \
        ; \
    apk add --no-cache \
        bash tini openssh=${OPENSSH_VERSION} rsync; \
    chmod +x /usr/local/bin/entrypoint.sh; \
    rm /etc/motd; \
    passwd -d root; \
    mkdir -p ~root/.ssh /etc/authorized_keys; \
    printf 'set /files/etc/ssh/sshd_config/AuthorizedKeysFile ".ssh/authorized_keys /etc/authorized_keys/%%u"\n'\
'set /files/etc/ssh/sshd_config/ClientAliveInterval 30\n'\
'set /files/etc/ssh/sshd_config/ClientAliveCountMax 5\n'\
'set /files/etc/ssh/sshd_config/PermitRootLogin yes\n'\
'set /files/etc/ssh/sshd_config/PasswordAuthentication yes\n'\
'set /files/etc/ssh/sshd_config/Port 22\n'\
'set /files/etc/ssh/sshd_config/AllowTcpForwarding no\n'\
'set /files/etc/ssh/sshd_config/Match[1]/Condition/Group "wheel"\n'\
'set /files/etc/ssh/sshd_config/Match[1]/Settings/AllowTcpForwarding yes\n'\
'save\n'\
'quit\n' | augtool; \
    cp -a /etc/ssh /etc/ssh.cache; \
    apk del .build-deps; \
    rm -rf /var/cache/apk/*;

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/entrypoint.sh"]
