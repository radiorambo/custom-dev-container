https://github.com/radiorambo/custom-dev-container/pkgs/container/custom-dev-container

# custom-dev-container

A custom Docker dev container image based on **Arch Linux**, with Node.js, Bun, Python, and the Fresh terminal editor preinstalled.

Rebuilt twice a month via GitHub Actions.

## Image

Pulled from GHCR:

```
ghcr.io/radiorambo/custom-dev-container:latest
```

## What's included

- Arch Linux (rolling)
- Bun (latest, official release tarball)
- `npm` and `npx` aliases mapped to `bun` and `bunx`
- Python + pip (from `pacman`)
- OpenCode CLI (from `[extra]`)
- Vite+ CLI (`vp`, from `https://vite.plus`)
- Fresh editor (latest, from chaotic-aur)
- Common CLI tools: `git`, `curl`, `sudo`, `unzip`, `xz`
- Obscura headless browser (for browser automation via MCP)
- OpenCode MCP server: Obscura (`obscura mcp`)

## OpenCode MCP

Obscura is installed from its prebuilt GitHub release archive and configured as
the OpenCode MCP server with `obscura mcp`. It is enabled automatically in
OpenCode.

## Schedule

The workflow runs on a twice-monthly cron (`0 3 1,15 * *`) — 03:00 UTC on the 1st and 15th of each month. It can also be triggered manually from the Actions tab.

Note: GitHub's cron syntax has no biweekly primitive, so `1,15` is the standard approximation.

## Usage

```bash
podman run -it --rm \
  --userns=keep-id:uid=0,gid=0 \
  -v "$PWD:/workspace" \
  --workdir /workspace \
  ghcr.io/radiorambo/custom-dev-container:latest
```

The image intentionally runs all applications as `root` inside the container.
Use rootless Podman with `keep-id:uid=0,gid=0` so container UID/GID 0 maps to
the invoking host user. Files created in `/workspace` are therefore owned by
the host user, not host root. Podman does not fix ownership automatically for
arbitrary `--userns` settings; this option is required for this image.

```bash
podman pull ghcr.io/radiorambo/custom-dev-container:latest
```

Verify the mapping:

```bash
podman run --rm \
  --userns=keep-id:uid=0,gid=0 \
  -v "$PWD:/workspace" \
  --workdir /workspace \
  ghcr.io/radiorambo/custom-dev-container:latest \
  sh -c 'touch .permission-check-container'
stat -c '%U:%G %a %n' .permission-check-container
rm .permission-check-container
```

Do not add `:U` to the bind mount: it recursively changes ownership on the
host and is unnecessary with `keep-id`.

### Why Podman

This container is a temporary development environment that needs unrestricted
root access for its tools. Rootful Docker would give container root more direct
host impact if the container or a mounted service were compromised. Rootless
Podman places the container in a user namespace: `root` is privileged inside
the container but not privileged on the host. Do not use `--privileged`, mount
the host Docker/Podman socket, or run Podman itself as root.

The GitHub workflow still uses Docker Buildx for portable registry publishing;
Podman is the local runtime.

Inside the container:

```bash
bun --version
bunx --version
python --version
python3 --version
fresh --version
opencode --version
fresh
opencode
```

### JavaScript runtime decision

The image intentionally does not include Node.js, npm, or pnpm to reduce its
size. In interactive Bash sessions, `npm` is aliased to `bun` and `npx` to
`bunx`.

If a project specifically requires Node.js or pnpm, install the needed tool
for that session rather than adding it to the base image:

```bash
pacman -Syu --noconfirm nodejs-lts pnpm
```

## Versioning

Bun and Fresh are resolved to their **latest** GitHub release at every build. Combined with the twice-monthly cron, the image always has current versions within ~15 days of upstream.

## Notes

- The image is published to GHCR. Visibility follows the repository: public repo → public image.
- Tagged `latest` is updated on every successful default-branch build; scheduled runs get a `YYYYMMDD-biweekly` tag.
- Layer caching uses GitHub Actions cache (`type=gha`) for faster rebuilds.
- Provenance attestations and SBOMs are enabled on every push.
