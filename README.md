# reefy-dev-ubuntu

Ubuntu 24.04 with **systemd as PID 1**, packaged for use as a development
environment container.

The base image for the **dev-ubuntu** app on
[Reefy](https://reefy.ai) - turn your home server into a Reef.

## What's in the image

- `ubuntu:24.04` base
- `systemd` + `systemd-sysv` so the container behaves like a Linux host
  (unit-managed services, journald, cron, sshd, udev, ...)
- Container-friendly pruning of default systemd units that don't make
  sense in a container (initctl, plymouth, conflicting udev sockets,
  most `multi-user.target.wants/*`, ...)

Build/dev dependencies (gcc, qemu, parted, mtools, ...) are NOT baked
in - they live in the consuming project's setup script so this image
rebuilds rarely.

## Tags

- `24.04`, `latest` - Ubuntu 24.04 LTS

Pull from `ghcr.io/reefyai/reefy-dev-ubuntu`.

## Runtime requirements

systemd-as-PID-1 needs cgroup access + tmpfs for `/run` and `/tmp`:

```bash
docker run -d \
  --privileged \
  -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
  --tmpfs /run --tmpfs /tmp \
  ghcr.io/reefyai/reefy-dev-ubuntu:24.04
```

## Reefy app spec

The catalog spec for the Reefy `dev-ubuntu` app lives under
[`reefy/app.json`](reefy/app.json). It wires the runtime requirements
above plus KVM passthrough, host `/dev` mount, and a `/build` volume
for non-backed-up build artifacts.

## License

[MIT](LICENSE).
