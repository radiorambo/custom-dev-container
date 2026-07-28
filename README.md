# custom-dev-container

A custom Docker dev container image based on **Arch Linux**, with Node.js, Bun, Python, and the Fresh terminal editor preinstalled.

Rebuilt automatically every two weeks via GitHub Actions.

## Image

Pulled from GHCR:

```
ghcr.io/<owner>/custom-dev-container:latest
```

## What's included

- Arch Linux (rolling)
- Node.js + npm (from `pacman`)
- Bun (official installer)
- Python + pip (from `pacman`)
- Fresh editor (official installer)
- Common CLI tools: `git`, `curl`, `wget`, `sudo`

## Schedule

The workflow runs on a biweekly cron (`0 3 1,15 * *`) — 03:00 UTC on the 1st and 15th of each month. It can also be triggered manually from the Actions tab.

## Usage

```bash
docker run -it --rm ghcr.io/<owner>/custom-dev-container:latest
```

Inside the container:

```bash
node --version
bun --version
python --version
fresh
```

## Notes

- The image is published publicly to GHCR from the default branch.
- Tagged `latest` is updated on every successful default-branch build; scheduled runs get a `YYYYMMDD-biweekly` tag.
- Layer caching uses GitHub Actions cache (`type=gha`) for faster rebuilds.