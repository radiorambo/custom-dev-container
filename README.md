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
- Python + pip (from `pacman`)
- Fresh editor (latest, official release tarball)
- Common CLI tools: `git`, `curl`, `wget`, `sudo`, `unzip`, `xz`

## Schedule

The workflow runs on a twice-monthly cron (`0 3 1,15 * *`) — 03:00 UTC on the 1st and 15th of each month. It can also be triggered manually from the Actions tab.

Note: GitHub's cron syntax has no biweekly primitive, so `1,15` is the standard approximation.

## Usage

```bash
docker run -it --rm ghcr.io/radiorambo/custom-dev-container:latest
```

Inside the container:

```bash
bun --version
python --version
python3 --version
fresh --version
fresh
```

## Versioning

Bun and Fresh are resolved to their **latest** GitHub release at every build. Combined with the twice-monthly cron, the image always has current versions within ~15 days of upstream.

## Notes

- The image is published to GHCR. Visibility follows the repository: public repo → public image.
- Tagged `latest` is updated on every successful default-branch build; scheduled runs get a `YYYYMMDD-biweekly` tag.
- Layer caching uses GitHub Actions cache (`type=gha`) for faster rebuilds.
- Provenance attestations and SBOMs are enabled on every push.