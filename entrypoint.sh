#!/bin/bash

# Ensure $HOME exists when starting
if [ ! -d "${HOME}" ]; then
  mkdir -p "${HOME}"
fi

# Add current (arbitrary) user to /etc/passwd and /etc/group
if ! whoami &> /dev/null; then
  if [ -w /etc/passwd ]; then
    echo "${USER_NAME:-user}:x:$(id -u):0:${USER_NAME:-user} user:${HOME}:/bin/bash" >> /etc/passwd
    echo "${USER_NAME:-user}:x:$(id -u):" >> /etc/group
  fi
fi

# Kubedock
if [ "${KUBEDOCK_ENABLED:-false}" = "true" ]; then
    echo
    echo "Kubedock is enabled (env variable KUBEDOCK_ENABLED is set to true)."

    SECONDS=0
    KUBEDOCK_TIMEOUT=${KUBEDOCK_TIMEOUT:-10}
    until [ -f $KUBECONFIG ]; do
        if (( SECONDS > KUBEDOCK_TIMEOUT )); then
            break 
        fi
        echo "Kubeconfig doesn't exist yet. Waiting..."
        sleep 1
    done

    if [ -f $KUBECONFIG ]; then 
        echo "Kubeconfig found."

        KUBEDOCK_PARAMS=${KUBEDOCK_PARAMS:-"--reverse-proxy --kubeconfig $KUBECONFIG"}

        echo "Starting kubedock with params \"${KUBEDOCK_PARAMS}\"..."
        
        kubedock server ${KUBEDOCK_PARAMS} > /tmp/kubedock.log 2>&1 &
        
        echo "Done."

        echo "Replacing podman with podman-wrapper..."

        ln -f -s /usr/bin/podman.wrapper /home/user/.local/bin/podman

        export TESTCONTAINERS_RYUK_DISABLED="true"
        export TESTCONTAINERS_CHECKS_DISABLE="true"

        echo "Done."
        echo
    else 
        echo "Could not find Kubeconfig at $KUBECONFIG"
        echo "Giving up..."
    fi
else
    echo
    echo "Kubedock is disabled. It can be enabled with the env variable \"KUBEDOCK_ENABLED=true\""
    echo "set in the workspace Devfile or in a Kubernetes ConfigMap in the developer namespace."
    echo
    mkdir -p /home/user/.local/bin
    ln -f -s /usr/bin/podman.orig /home/user/.local/bin/podman
fi


exec "$@"