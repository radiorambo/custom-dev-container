https://github.com/radiorambo/custom-dev-container/pkgs/container/custom-dev-container

# custom-dev-container

A custom Docker dev container image based on **Arch Linux**, with a web desktop (XFCE + Selkies/noVNC), Docker-in-Docker, Node.js, Bun, Python, Chromium, and the Fresh terminal editor preinstalled.

Rebuilt twice a month via GitHub Actions.

## Image

Pulled from GHCR:

```
ghcr.io/radiorambo/custom-dev-container:latest
```

## What's included

Base is `lscr.io/linuxserver/webtop:arch-xfce`, plus this repo's layers:

- Arch Linux (rolling) + XFCE desktop (Thunar, mousepad) via Selkies/noVNC web UI (HTTPS 10101, HTTP 10100, WebSocket 10102)
- Docker-in-Docker: `docker` + `dockerd` 29.8.1, `docker compose` 5.5.1, `containerd` 2.4.0 (from the WebTop base; `svc-docker`, `START_DOCKER=true` by default)
- Bun 1.4.2 (latest release tarball at build time)
- `npm` and `npx` aliases mapped to `bun` and `bunx`
- Node.js (system, from `pacman`) + Python 3.14 + pip (from `pacman`)
- OpenCode CLI (from `[extra]`)
- Vite+ CLI (`vp`, from `https://vite.plus`)
- Fresh editor (latest, from chaotic-aur)
- Common CLI tools: `git`, `curl`, `sudo`, `jq`, `unzip`, `xz`, `which`, `ca-certificates`
- Chromium via in-place `--no-sandbox` wrapper (`/usr/bin/chromium` → real binary at `chromium.real`; menu uses absolute path, so shadowing `PATH` was not enough)
- Obscura headless browser (for browser automation via MCP)
- OpenCode MCP server: Obscura (`obscura mcp`)
- CLI-first shell (append `bash` to `run`, GUI stays backgrounded) + `gui` helper (prints desktop URLs, curl-checks `https://localhost:10101`)

## OpenCode MCP

Obscura is installed from its prebuilt GitHub release archive and configured as
the OpenCode MCP server with `obscura mcp`. It is enabled automatically in
OpenCode.

## Schedule

The workflow runs on a twice-monthly cron (`0 3 1,15 * *`) — 03:00 UTC on the 1st and 15th of each month. It can also be triggered manually from the Actions tab.

Note: GitHub's cron syntax has no biweekly primitive, so `1,15` is the standard approximation.

## Usage (CLI-first, GUI in background)

`ENTRYPOINT` is LinuxServer `/init` (s6 + Selkies). A bare
`docker run -it ... image` attaches to init logs, not a usable shell.
Append `bash` for a foreground shell — the GUI keeps running behind it.

Foreground shell (where most work happens):

```bash
docker run -it --rm \
  --privileged \
  -e PUID=0 -e PGID=0 \
  --shm-size=1gb \
  -p 127.0.0.1:10100-10110:10100-10110 \
  -v docker-lib:/var/lib/docker \
  -v "$PWD:/workspace" \
  --workdir /workspace \
  ghcr.io/radiorambo/custom-dev-container:latest bash
```

Detached server + exec (long-lived container):

```bash
docker run -d --name dev \
  --privileged \
  -e PUID=0 -e PGID=0 \
  --shm-size=1gb \
  -p 127.0.0.1:10100-10110:10100-10110 \
  -v docker-lib:/var/lib/docker \
  -v "$PWD:/workspace" \
  --workdir /workspace \
  ghcr.io/radiorambo/custom-dev-container:latest
docker exec -it dev bash
docker logs -f dev
```

Do not run detached as `run -d ... image bash` without `-t` — bash exits
immediately and the container stops. For detached mode pass no command
and use `exec` above.

Open the desktop at **https://localhost:10101** and accept the local
self-signed certificate. HTTP uses 10100, HTTPS 10101, and WebSocket 10102;
the remaining ports in 10100–10110 are available for development services.
Inside the container `gui` prints the URLs and curl-checks the GUI port.
`exit` / `Ctrl+D` in the foreground-shell mode stops the container and
its GUI by design — use detached mode to keep it running.

The image intentionally runs all applications as `root` inside the container.
The outer runtime is rootful Docker, so container UID 0 maps to host root:
files created in the `/workspace` bind mount are owned by host `root`.
`chown` them on the host as needed. `PUID=0` and `PGID=0` keep LinuxServer
running the desktop as root inside the container, which is required for this
image's `/root`-based tool configuration.

```bash
docker pull ghcr.io/radiorambo/custom-dev-container:latest
```

### Docker-in-Docker (preinstalled, no image changes needed)

`dockerd` ships in the WebTop base behind the s6 `svc-docker` service, which
starts only when **both** conditions hold:

1. `--privileged` on the outer `run` (exposes `/dev/cpu_dma_latency`, the s6 gate), and
2. `START_DOCKER=true` (already the image default — no `-e` needed).

A named volume at `/var/lib/docker` is required, not optional: without it,
pulls succeed but every inner `run` fails with
`failed to mount … fstype: overlay … invalid argument` (overlay-on-overlay).
The volume also persists pulled images across container recreates.

```bash
docker exec dev docker run --rm alpine echo hello
docker exec dev docker compose version
```

Inner `dockerd` takes ~20s to come up on first start. Inner published ports
are invisible on the host unless re-mapped at the outer level within
10100–10110.

### Why Docker (runtime decision)

The outer runtime used to be rootless Podman. That was deliberately switched
to rootful Docker because Podman added per-feature translation complexity to
every implementation and change:

- `--userns=keep-id:uid=0,gid=0` mapping on every command, plus host
  `/etc/subuid`/`/etc/subgid` mounts for anything nested,
- `--device /dev/fuse` + `fuse-overlayfs` driver pinning for inner storage,
- `--cap-add` / `--security-opt seccomp=unconfined` workarounds per workload,
- overlay-on-overlay and cgroup-delegation quirks that needed re-verification
  for each new use (nested runtimes, inner networking, inner builds),
- silent failure modes (e.g. s6 `svc-docker` sleeping forever with no error
  when the privileged probe file is absent).

Docker is the native path for this image: the base already ships `dockerd` +
`svc-docker`, the GitHub workflow already builds with Docker Buildx, and the
entire DinD story is one flag (`--privileged`) plus one volume. The tradeoff
is host posture — container root is host root (see above) — accepted because
this is a local, temporary dev environment, not shared infrastructure.

### `just container` helper

`~/.config/just/container/temp.just` wraps the detached pattern: `just
container start` creates the `temp-docker-lib` volume and `temp` container if
needed, prints the GUI endpoints, and `exec`s into `bash`. The container is
`--rm`, so `docker stop temp` after exiting the shell removes it.
`just container shell` attaches to the running `temp` container.

Previously the helper also trapped `HUP`/`TERM` to guarantee cleanup when the
terminal died:

```bash
cleanup() {
    docker stop --time 0 temp >/dev/null 2>&1 || true
}
trap cleanup HUP TERM
rc=0
docker exec -it temp bash || rc=$?
cleanup
trap - HUP TERM
exit "$rc"
```

That was removed to keep `start` minimal — with `--rm`, an exited shell plus
a manual `docker stop temp` covers the normal cases. Re-add the snippet above
in place of the bare `docker exec -it temp bash` if orphaned `temp`
containers start appearing after killed terminals.

## Appendix: previous Podman setup (kept for switch-back reference)

The `trap` + `cleanup`-on-exit pattern in the `just` helper originated in the
Podman era and is runtime-agnostic — only the CLI name and flags differ. If we
ever switch back to rootless Podman, this is the known-good recipe:

```bash
podman run -d --rm \
  --userns=keep-id:uid=0,gid=0 \
  --name=temp \
  -e PUID=0 -e PGID=0 -e TZ="UTC" \
  -p "127.0.0.1:10100-10110:10100-10110" \
  -v "$HOME/Downloads:/workspace/downloads" \
  --shm-size=1gb \
  --security-opt seccomp=unconfined \
  ghcr.io/radiorambo/custom-dev-container:latest
```

with the same wrapper logic:

```bash
cleanup() {
    podman stop --time 0 temp >/dev/null 2>&1 || true
}
trap cleanup HUP TERM
rc=0
podman exec -it temp bash || rc=$?
cleanup
trap - HUP TERM
exit "$rc"
```

Podman-era notes: files in bind mounts were owned by the host user (not host
root) thanks to `keep-id:uid=0,gid=0`; nested container use additionally
required `--device /dev/fuse`, `-v /etc/subuid:/etc/subuid:ro` (+ `subgid`),
and `--cap-add=SYS_ADMIN,NET_ADMIN,NET_RAW`. Inner Docker via `svc-docker`
never worked reliably under rootless Podman for this image, which was a major
driver of the switch.

Inside the container:

```bash
bun --version
bunx --version
python --version
python3 --version
fresh --version
opencode --version
docker --version
docker compose version
gui        # desktop URLs + HTTPS health check
fresh
opencode
```

### JavaScript runtime decision

The image includes system Node.js and Bun. In interactive Bash sessions,
`npm` is aliased to `bun` and `npx` to `bunx`.

If a project specifically requires pnpm, install it for that session:

```bash
pacman -Syu --noconfirm pnpm
```

## Versioning

Bun and Fresh are resolved to their **latest** GitHub release at every build. Combined with the twice-monthly cron, the image always has current versions within ~15 days of upstream.

## Notes

- The image is published to GHCR. Visibility follows the repository: public repo → public image.
- Tagged `latest` is updated on every successful default-branch build; scheduled runs get a `YYYYMMDD-biweekly` tag.
- Layer caching uses GitHub Actions cache (`type=gha`) for faster rebuilds.
- Provenance attestations and SBOMs are enabled on every push.
