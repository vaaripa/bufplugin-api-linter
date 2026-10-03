# ubuntu:22.04
FROM ubuntu@sha256:1aa979d85661c488ce030ac292876cf6ed04535d3a237e49f61542d8e5de5ae0

ARG TARGETARCH
ARG USERNAME=developer
ARG USER_UID=1000
ARG USER_GID=1000

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && \
    apt install -y --no-install-recommends \
    ca-certificates \
    curl \
    sudo \
    git \
    ssh \
    python3-pip

# pre-commit
RUN python3 -m pip install pre-commit

# golang
RUN GO_VERSION=1.27.1 && \
    curl -L https://go.dev/dl/go$GO_VERSION.linux-$TARGETARCH.tar.gz | tar xvz -C /usr/local
ENV PATH="$PATH:/usr/local/go/bin"

RUN groupadd --gid $USER_GID $USERNAME && \
    useradd --uid $USER_UID --gid $USER_GID -ms /bin/bash $USERNAME && \
    echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME

USER developer
