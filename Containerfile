
FROM registry.fedoraproject.org/fedora-minimal:latest as builder


RUN microdnf -y install git sudo tar which zsh python3.12 && \
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


RUN useradd user && \
    mkdir -p /home/user && \
    chown -R user:user /home/user && \
    echo "user ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    chsh -s $(which zsh) user

USER user
WORKDIR /home/user

RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" && \
    /usr/bin/python3.12 -m pip install ansible-dev-tools


ENV TERM=xterm-256color
ENV SHELL=/usr/bin/zsh
