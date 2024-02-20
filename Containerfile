####################
## Build kubedock ## ----------------------------------------------------------
####################

FROM docker.io/golang:1.21 AS kubedock

ARG KD_REPO=https://github.com/joyrex2001/kubedock

RUN git clone ${KD_REPO} \
    && cd kubedock \
    && make test build \
    && mkdir /app \
    && cp kubedock /app


#################
## Final image ## ------------------------------------------------------------
#################
FROM registry.fedoraproject.org/fedora-minimal:latest

COPY --from=kubedock /app /usr/local/bin

RUN microdnf -y install git sudo tar which stow zsh podman python3.12 && \
    microdnf clean all && \
    /usr/bin/python3.12 -m ensurepip --default-pip && \
    /usr/bin/python3.12 -m pip install --upgrade pip
    
## kubectl
RUN \
    curl -LO https://dl.k8s.io/release/`curl -LS https://dl.k8s.io/release/stable.txt`/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin && \
    kubectl version --client

## helm
RUN \
    TEMP_DIR="$(mktemp -d)" && \
    cd "${TEMP_DIR}" && \
    HELM_VERSION="3.7.0" && \
    HELM_ARCH="linux-amd64" && \
    HELM_TGZ="helm-v${HELM_VERSION}-${HELM_ARCH}.tar.gz" && \
    HELM_TGZ_URL="https://get.helm.sh/${HELM_TGZ}" && \
    curl -sSLO "${HELM_TGZ_URL}" && \
    curl -sSLO "${HELM_TGZ_URL}.sha256sum" && \
    sha256sum -c "${HELM_TGZ}.sha256sum" 2>&1 | grep OK && \
    tar -zxvf "${HELM_TGZ}" && \
    mv "${HELM_ARCH}"/helm /usr/local/bin/helm && \
    cd - && \
    rm -rf "${TEMP_DIR}"


USER 0
ENV HOME=/home/tooling
RUN mkdir -p /home/tooling/

# Configure the podman wrapper
COPY --chown=0:0 podman.py /usr/bin/podman.wrapper
RUN chmod +x /usr/bin/podman.wrapper
RUN mv /usr/bin/podman /usr/bin/podman.orig

# Install oh-my-zsh and ansible-dev-tools
RUN 

COPY --chown=0:0 entrypoint.sh /
COPY --chown=0:0 .stow-local-ignore /home/tooling/
RUN \
    # add user and configure it
    useradd -u 10001 -G wheel,root -d /home/user --shell /usr/bin/bash -m user && \
    # Setup $PS1 for a consistent and reasonable prompt
    # touch /etc/profile.d/udi_prompt.sh && \
    # chown 10001 /etc/profile.d/udi_prompt.sh && \
    # echo "export PS1='\W \`git branch --show-current 2>/dev/null | sed -r -e \"s@^(.+)@\(\1\) @\"\`$ '" >> /etc/profile.d/udi_prompt.sh && \
    # Copy the global git configuration to user config as global /etc/gitconfig
    # file may be overwritten by a mounted file at runtime
    # cp /etc/gitconfig ${HOME}/.gitconfig && \
    chown 10001 ${HOME}/ ${HOME}/.viminfo ${HOME}/.gitconfig ${HOME}/.stow-local-ignore && \
    # Set permissions on /etc/passwd and /home to allow arbitrary users to write
    chgrp -R 0 /home && \
    chmod -R g=u /etc/passwd /etc/group /home && \
    chmod +x /entrypoint.sh && \
    # Create symbolic links from /home/tooling/ -> /home/user/
    stow . -t /home/user/ -d /home/tooling/ && \
    # .viminfo cannot be a symbolic link for security reasons, so copy it to /home/user/
    cp /home/tooling/.viminfo /home/user/.viminfo && \
    # Bash-related files are backed up to /home/tooling/ incase they are deleted when persistUserHome is enabled.
    cp /home/user/.bashrc /home/tooling/.bashrc && \
    cp /home/user/.bash_profile /home/tooling/.bash_profile && \
    chown 10001 /home/tooling/.bashrc /home/tooling/.bash_profile && \
    # nodejs 18 + VSCODE_NODEJS_RUNTIME_DIR are required on ubi9 based images
    # until we fix https://github.com/eclipse/che/issues/21778
    # When fixed, we won't need this Dockerfile anymore.
    # c.f. https://github.com/che-incubator/che-code/pull/120
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash && \
    export NVM_DIR="$HOME/.nvm" && \
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && \
    nvm install 18.18.0 && \
    cp -R /home/user/.nvm /home/tooling/.nvm &&
    # zsh
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" && \
    cp -R /home/user/.oh-my-zsh /home/tooling/.oh-my-zsh &&
    cp /home/user/.zshrc /home/tooling/.zshrc &&
    # dev tools
    /usr/bin/python3.12 -m pip install ansible-dev-tools $$ \
    cp -R /home/user/.local/lib /home/tooling/.local/lib && \
    cp -R /home/user/.local/bin /home/tooling/.local/bin




ENV KUBECONFIG=/home/user/.kube/config
ENV KUBEDOCK_ENABLED=true
ENV CONTAINER_HOST=tcp://127.0.0.1:2475
ENV VSCODE_NODEJS_RUNTIME_DIR="$HOME/.nvm/versions/node/v18.18.0/bin/"


USER 10001
ENV HOME=/home/user
WORKDIR /projects
ENTRYPOINT [ "/entrypoint.sh" ]
CMD ["tail", "-f", "/dev/null"]

