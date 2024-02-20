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
FROM quay.io/devfile/universal-developer-image:latest

COPY --from=kubedock /app /usr/local/bin

USER 0

## Ansible dev tools
ARG PYV=3.11
RUN /usr/bin/python${PYV} -m pip install ansible-dev-tools

# Configure the podman wrapper
COPY --chown=0:0 podman.py /usr/bin/podman.wrapper
RUN chmod +x /usr/bin/podman.wrapper

USER 10001