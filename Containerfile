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

RUN microdnf -y install git sudo tar which zsh podman python3.12 nodejs && \
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




# Configure the podman wrapper
COPY --chown=0:0 podman.py /usr/bin/podman.wrapper
RUN chmod +x /usr/bin/podman.wrapper
RUN mv /usr/bin/podman /usr/bin/podman.orig


# Set the perm for /home/tooling
RUN mkdir /home/tooling && chgrp -R 0 /home/tooling && chmod -R g=u /home/tooling

# Create a non-root user
RUN useradd -m -d /home/user user && \
    echo "user ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    chsh -s $(which zsh) user

USER user
ENV HOME=/home/user
WORKDIR /home/user

# nodejs 18 + VSCODE_NODEJS_RUNTIME_DIR are required on ubi9 based images
# until we fix https://github.com/eclipse/che/issues/21778
# When fixed, we won't need this Dockerfile anymore.
# c.f. https://github.com/che-incubator/che-code/pull/120
RUN \
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash && \
export NVM_DIR="$HOME/.nvm" && \
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && \
nvm install 18.18.0
ENV VSCODE_NODEJS_RUNTIME_DIR="$HOME/.nvm/versions/node/v18.18.0/bin/"

# Install oh-my-zsh and ansible-dev-tools
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" && \
    /usr/bin/python3.12 -m pip install ansible-dev-tools

USER root
# Set permissions on /etc/passwd, /etc/group, /etc/pki and /home to allow arbitrary users to write
RUN chgrp -R 0 /home && chmod -R g=u /etc/passwd /etc/group /home /etc/pki

# cleanup dnf cache
COPY --chown=0:0 entrypoint.sh /

USER user

