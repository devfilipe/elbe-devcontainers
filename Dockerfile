FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive

# Base utilities
RUN apt-get update && apt-get install -y \
    wget ca-certificates apt-transport-https gnupg \
    sudo curl vim less \
    && rm -rf /var/lib/apt/lists/*

# Add ELBE repository (linutronix)
RUN wget -O /usr/share/keyrings/elbe-archive-keyring.gpg \
        http://debian.linutronix.de/elbe/elbe-repo.pub.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/elbe-archive-keyring.gpg] \
        http://debian.linutronix.de/elbe bookworm main" \
        > /etc/apt/sources.list.d/elbe.list

# Install ELBE, QEMU (ELBE 15+ uses --qemu mode, no libvirt needed)
RUN apt-get update && apt-get install -y \
    elbe qemu-system-x86 qemu-utils ovmf \
    && rm -rf /var/lib/apt/lists/*

# Cross-arch emulation
RUN apt-get update && apt-get install -y \
    qemu-user-static binfmt-support \
    && rm -rf /var/lib/apt/lists/*

# Tools for building Debian packages and local apt repo
RUN apt-get update && apt-get install -y \
    build-essential debhelper dpkg-dev fakeroot apt-utils \
    python3 python3-pip python3-venv \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# ELBE UI - lightweight web interface
# ---------------------------------------------------------------------------
COPY tools/elbe-ui /opt/elbe-ui
RUN pip3 install --no-cache-dir --break-system-packages -r /opt/elbe-ui/requirements.txt

# Create developer user matching host UID/GID
ARG USERNAME=developer
ARG USER_UID=1000
ARG USER_GID=1000

RUN groupadd --gid ${USER_GID} ${USERNAME} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

# Grant access to /dev/kvm
RUN groupadd -f kvm \
    && usermod -aG kvm ${USERNAME}

RUN mkdir -p /workspace && chown ${USERNAME}:${USERNAME} /workspace

# Entrypoint: starts daemons before handing off to shell
COPY tools/elbe-devcontainers/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Ports: 7587 = ELBE initvm SOAP, 8080 = ELBE UI web interface
EXPOSE 7587 8080

CMD ["su", "-", "developer", "-c", "cd /workspace && exec bash"]
