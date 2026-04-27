# reefy-dev-ubuntu: Ubuntu 24.04 with systemd as PID 1.
#
# Used by the dev-ubuntu Reefy app to give the container a full-VM-like
# experience: udev for partition device nodes, cron, sshd as a unit,
# journald, etc. Build/e2e dependencies stay in tools/dev-host/setup.sh
# (NOT baked here) so this image rebuilds rarely and per-user
# customisation has one source of truth.
#
# Pattern follows jrei/systemd-ubuntu but vendored into our own org so
# the supply chain stays under our control. CI rebuilds on push to main
# touching this file (.github/workflows/dev-ubuntu-image.yml).

FROM ubuntu:24.04

LABEL org.opencontainers.image.title="reefy-dev-ubuntu" \
      org.opencontainers.image.description="Ubuntu 24.04 with systemd as PID 1. Base image for the dev-ubuntu app on https://reefy.ai" \
      org.opencontainers.image.licenses="MIT"

ENV container=docker \
    LC_ALL=C \
    DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends systemd systemd-sysv \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

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
