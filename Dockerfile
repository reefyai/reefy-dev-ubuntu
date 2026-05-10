# reefy-dev-ubuntu: Ubuntu 24.04 with systemd as PID 1.
#
# Full-VM-like container with systemd unit management, journald, sshd,
# cron, udev, basic CLI (ip/ss/ping/sudo/less/vim/jq/curl), build
# toolchain (gcc/make/python), Linux image tooling
# (parted/mtools/dosfstools/cpio/zip), and modern secret tooling
# (sops + age). General-purpose Linux dev sandbox.
#
# Pattern follows jrei/systemd-ubuntu but vendored to our org so the
# supply chain stays under our control. CI rebuilds on Dockerfile change.

FROM ubuntu:24.04

LABEL org.opencontainers.image.title="reefy-dev-ubuntu" \
      org.opencontainers.image.description="Ubuntu 24.04 with systemd as PID 1. Base image for the dev-ubuntu app on https://reefy.ai" \
      org.opencontainers.image.licenses="MIT"

ENV container=docker \
    LC_ALL=C \
    DEBIAN_FRONTEND=noninteractive

# Single big apt RUN so all packages share one layer (smaller image).
# Categories:
#   - systemd + basic CLI: full-VM feel
#   - build-essential + python: general build toolchain
#   - bc/bison/flex/libssl-dev/libelf-dev/libncurses-dev/cpio: kernel +
#     buildroot-style image build deps
#   - systemd-boot-efi: UEFI bootloader stub (linuxx64.efi.stub)
#   - ragel: state-machine parser generator
#   - mtools/gdisk/parted/dosfstools/zip: disk image partition tooling
#   - age: file encryption (SOPS recipients, etc.)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        systemd systemd-sysv \
        sudo less vim jq curl tmux nano git \
        iproute2 iputils-ping net-tools \
        ca-certificates openssh-client openssh-sftp-server \
        build-essential python3 python3-pip python3-venv \
        bc bison flex libssl-dev libelf-dev libncurses-dev \
        unzip cpio rsync file bzip2 wget patch \
        systemd-boot-efi ragel \
        mtools gdisk parted dosfstools zip \
        age \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# SOPS (Mozilla's secret encryption tool). Single Go binary not in
# apt; fetched from upstream releases.
ARG SOPS_VERSION=v3.13.0
RUN curl --retry 5 --retry-delay 5 --retry-all-errors --retry-max-time 300 \
        -fsSL "https://github.com/getsops/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux.amd64" \
        -o /usr/local/bin/sops \
    && chmod +x /usr/local/bin/sops

# Prune systemd units that don't belong in a container. Pattern from
# jrei/systemd-ubuntu - removes auto-started units that try to talk to
# kernel subsystems that aren't there in a container (initctl, plymouth,
# udev sockets that conflict with host's udev, etc).
RUN cd /lib/systemd/system/sysinit.target.wants/ \
    && ls | grep -v systemd-tmpfiles-setup | xargs rm -f $1
RUN rm -f /lib/systemd/system/multi-user.target.wants/* \
    /etc/systemd/system/*.wants/* \
    /lib/systemd/system/local-fs.target.wants/* \
    /lib/systemd/system/sockets.target.wants/*udev* \
    /lib/systemd/system/sockets.target.wants/*initctl* \
    /lib/systemd/system/basic.target.wants/* \
    /lib/systemd/system/anaconda.target.wants/* \
    /lib/systemd/system/plymouth* \
    /lib/systemd/system/systemd-update-utmp*

# /sys/fs/cgroup is bind-mounted from the host at runtime via
# host_mounts in apps/dev-ubuntu/app.json; declaring as VOLUME makes
# `docker run` complain less if the mount is missing.
VOLUME [ "/sys/fs/cgroup" ]

CMD ["/lib/systemd/systemd"]
