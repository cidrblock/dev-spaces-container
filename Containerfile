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
FROM quay.io/devfile/base-developer-image:ubi9-latest
LABEL maintainer="Red Hat, Inc."

LABEL com.redhat.component="devfile-universal-container"
LABEL name="devfile/universal-developer-image"
LABEL version="ubi8"

#label for EULA
LABEL com.redhat.license_terms="https://www.redhat.com/en/about/red-hat-end-user-license-agreements#UBI"

#labels for container catalog
LABEL summary="devfile universal developer image"
LABEL description="Image with developers tools. Languages SDK and runtimes included."
LABEL io.k8s.display-name="devfile-developer-universal"
LABEL io.openshift.expose-services=""
COPY --from=kubedock /app /usr/local/bin

USER 0

# $PROFILE_EXT contains all additions made to the bash environment
ENV PROFILE_EXT=/etc/profile.d/udi_environment.sh
RUN touch ${PROFILE_EXT} & chown 10001 ${PROFILE_EXT}
    
## kubectl
RUN <<EOF
set -euf -o pipefail

cat <<EOF2 > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF2

dnf install -y kubectl
# curl -sSL -o ~/.kubectl_aliases https://raw.githubusercontent.com/ahmetb/kubectl-alias/master/.kubectl_aliases
# echo '[ -f ~/.kubectl_aliases ] && source ~/.kubectl_aliases' >> ${PROFILE_EXT}
EOF

## helm
RUN <<EOF
set -euf -o pipefail
TEMP_DIR="$(mktemp -d)"
cd "${TEMP_DIR}"
HELM_VERSION="3.7.0"
HELM_ARCH="linux-amd64"
HELM_TGZ="helm-v${HELM_VERSION}-${HELM_ARCH}.tar.gz"
HELM_TGZ_URL="https://get.helm.sh/${HELM_TGZ}"
curl -sSLO "${HELM_TGZ_URL}"
curl -sSLO "${HELM_TGZ_URL}.sha256sum"
sha256sum -c "${HELM_TGZ}.sha256sum" 2>&1 | grep OK
tar -zxvf "${HELM_TGZ}"
mv "${HELM_ARCH}"/helm /usr/local/bin/helm
cd -
rm -rf "${TEMP_DIR}"
EOF

## podman
RUN dnf -y install podman

##  python
ARG PYV=3.11
RUN dnf -y install python${PYV} python${PYV}-devel python${PYV}-setuptools python${PYV}-pip nss_wrapper

RUN cd /usr/bin \
    && if [ ! -L python ]; then ln -s python${PYV} python; fi \
    && if [ ! -L pydoc ]; then ln -s pydoc${PYV} pydoc; fi \
    && if [ ! -L python-config ]; then ln -s python${PYV}-config python-config; fi \
    && if [ ! -L pip ]; then ln -s pip-${PYV} pip; fi

RUN pip install pylint yq

## Ansible dev tools
RUN /usr/bin/python${PYV} -m pip install ansible-dev-tools

# Configure the podman wrapper
COPY --chown=0:0 podman.py /usr/bin/podman.wrapper
RUN chmod +x /usr/bin/podman.wrapper
RUN mv /usr/bin/podman /usr/bin/podman.orig

# cleanup dnf cache
RUN dnf -y clean all --enablerepo='*'

COPY --chown=0:0 entrypoint.sh /
RUN \
    # Set permissions on /etc/passwd and /home to allow arbitrary users to write
    # done in base image but again why?
    chgrp -R 0 /home && \
    chmod -R g=u /etc/passwd /etc/group /home && \
    chmod +x /entrypoint.sh

USER 10001
ENV HOME=/home/user
WORKDIR /projects
ENTRYPOINT [ "/entrypoint.sh" ]
CMD ["tail", "-f", "/dev/null"]