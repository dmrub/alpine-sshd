#!/bin/bash

message() {
    echo >&2 "[entrypoint.sh] $*"
}

info() {
    message "info: $*"
}

error() {
    echo >&2 "* [entrypoint.sh] Error: $*"
}

fatal() {
    error "$@"
    exit 1
}

message "info: EUID=$EUID args: $*"

usage() {
    echo "Entrypoint Script"
    echo
    echo ""
    echo "$0 [options]"
    echo "options:"
    echo "      --print-env            Display environment"
    echo "      --help"
    echo "      --help-entrypoint      Display this help and exit"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|--help-entrypoint)
            usage
            exit
            ;;
        --print-env)
            env >&2
            shift
            ;;
        --)
            shift
            break
            ;;
        -*)
            break
            ;;
        *)
            break
            ;;
    esac
done

# Initialization
info "Preparing container ..."

if [[ -n "${OPENSSH_ROOT_PASSWORD}" ]]; then
    info "Set root password"
    echo "root:${OPENSSH_ROOT_PASSWORD}" | /usr/sbin/chpasswd
else
    info "Delete root password"
    /usr/bin/passwd -d root
fi

if [[ -n "${OPENSSH_ROOT_AUTHORIZED_KEYS}" ]]; then
    info "Copy root's authorized keys"
    mkdir -p ~root/.ssh
    echo "${OPENSSH_ROOT_AUTHORIZED_KEYS}" >> ~root/.ssh/authorized_keys
    chmod 0700 ~root/.ssh
    chmod 0600 ~root/.ssh/authorized_keys
fi

OPENSSH_SHELL=${OPENSSH_SHELL:-/bin/bash}

if [[ -n "${OPENSSH_USER}" ]]; then
    info "Create user ${OPENSSH_USER}"

    /usr/sbin/addgroup -g "${OPENSSH_GROUPID}" "${OPENSSH_GROUP}"
    if [[ -d "${OPENSSH_HOME}" ]]; then
        /usr/sbin/adduser -u "${OPENSSH_USERID}" -G "${OPENSSH_GROUP}" -s "${OPENSSH_SHELL}" -h "${OPENSSH_HOME}" -H -D "${OPENSSH_USER}"
    else
        /usr/sbin/adduser -u "${OPENSSH_USERID}" -G "${OPENSSH_GROUP}" -s "${OPENSSH_SHELL}" -h "${OPENSSH_HOME}" -D "${OPENSSH_USER}"
    fi
    if [[ -n "${OPENSSH_PASSWORD}" ]]; then
        info "Set ${OPENSSH_USER}'s password"
        echo "${OPENSSH_USER}:${OPENSSH_PASSWORD}" | /usr/sbin/chpasswd
    else
        info "Delete ${OPENSSH_USER}'s password"
        /usr/bin/passwd -d "${OPENSSH_USER}"
    fi

    if [[ -n "${OPENSSH_AUTHORIZED_KEYS}" ]]; then
        info "Install authorized keys for $OPENSSH_USER user to $OPENSSH_HOME/.ssh/authorized_keys"
        mkdir -p "$OPENSSH_HOME/.ssh"
        chmod 755 "$OPENSSH_HOME"
        chmod 700 "$OPENSSH_HOME/.ssh"
        touch "$OPENSSH_HOME/.ssh/authorized_keys"
        echo "${OPENSSH_AUTHORIZED_KEYS}" >> "$OPENSSH_HOME/.ssh/authorized_keys"
        chmod 0600 "$OPENSSH_HOME/.ssh/authorized_keys";
        chown -R "$OPENSSH_USER:$OPENSSH_GROUP" "$OPENSSH_HOME";
    fi

    if [[ -n "${OPENSSH_ALLOW_TCP_FORWARDING}" ]]; then
        case "${OPENSSH_ALLOW_TCP_FORWARDING}" in
            yes|all|no|local|remote) ;;
            *) fatal "OPENSSH_ALLOW_TCP_FORWARDING is set to invalid value '$OPENSSH_ALLOW_TCP_FORWARDING', should be one of: yes | all | no | local | remote";;
        esac
        info "Set sshd option AllowTcpForwarding to ${OPENSSH_ALLOW_TCP_FORWARDING} for user ${OPENSSH_USER}"
        cat >> /etc/ssh/sshd_config <<EOF
Match User ${OPENSSH_USER}
  AllowTcpForwarding "${OPENSSH_ALLOW_TCP_FORWARDING}"
EOF
    fi
fi
unset OPENSSH_PASSWORD

OPENSSH_PORT=${OPENSSH_PORT:-22}
OPENSSH_CONTROLLER_PORT=${OPENSSH_CONTROLLER_PORT:-9090}

sed -i -e 's/Port[[:blank:]]\+[0-9]\+.*$/Port '"${OPENSSH_PORT}"'/g' /etc/ssh/sshd_config

export OPENSSH_USER OPENSSH_USERID \
       OPENSSH_GROUP OPENSSH_GROUPID OPENSSH_SHELL OPENSSH_HOME \
       OPENSSH_RUN OPENSSH_PORT

if [[ -n "$OPENSSH_RUN" ]]; then
    info "Executing: /bin/sh -c $OPENSSH_RUN"
    /bin/sh -c "$OPENSSH_RUN"
fi

# generate host keys if not present
ssh-keygen -A

# Run sshd
# -D      When this option is specified, sshd will not detach and does not become a daemon.
# -e      Write debug logs to standard error instead of the system log.
exec /usr/sbin/sshd -D -e "$@"
