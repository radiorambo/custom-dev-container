FROM lscr.io/linuxserver/webtop:arch-xfce

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    HOME=/root \
    PUID=0 \
    PGID=0 \
    CUSTOM_PORT=10100 \
    CUSTOM_HTTPS_PORT=10101 \
    CUSTOM_WS_PORT=10102 \
    PATH=/root/.local/share/vite-plus/bin:${PATH}

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm --needed \
        base \
        curl \
        git \
        ca-certificates \
        python \
        python-pip \
        nodejs \
        bun \
        opencode \
        unzip \
        xz \
        which \
        sudo \
        jq \
    && pacman -Scc --noconfirm

RUN pacman-key --init && \
    pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com && \
    pacman-key --lsign-key 3056513887B78AEB && \
    pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' && \
    pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' && \
    printf '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n' >> /etc/pacman.conf && \
    pacman -Syu fresh-editor --noconfirm && \
    pacman -Scc --noconfirm

RUN curl -fsSL https://github.com/h4ckf0r0day/obscura/releases/latest/download/obscura-x86_64-linux.tar.gz \
        -o /tmp/obscura.tar.gz && \
    tar -xzf /tmp/obscura.tar.gz -C /tmp && \
    install -m 0755 /tmp/obscura /usr/local/bin/obscura && \
    install -m 0755 /tmp/obscura-worker /usr/local/bin/obscura-worker && \
    rm -rf /tmp/obscura.tar.gz /tmp/obscura /tmp/obscura-worker && \
    curl -fsSL https://vite.plus | \
    VP_NODE_MANAGER=no VP_PM_MANAGER=no bash && \
    vp env off && \
    printf '%s\n' \
      "alias oc='opencode'" \
      "alias npm='bun'" \
      "alias npx='bunx'" \
      "# CLI-first helper: GUI runs backgrounded under s6 /init." \
      "# Prints URLs + health-checks Selkies HTTPS from inside the container." \
      "gui() {" \
      "  echo 'Desktop HTTPS: https://localhost:10101 (accept self-signed)'" \
      "  echo 'HTTP: http://localhost:10100 | WebSocket: 10102'" \
      "  if _out=\$(curl -ks -m 5 -o /dev/null -w 'GUI status %{http_code} (%{time_total}s)' https://localhost:10101 2>/dev/null); then echo \"\$_out\"; else echo 'GUI not responding yet - retry in a few seconds'; fi; unset _out" \
      "}" \
      >> /root/.bashrc

# Chromium's sandbox refuses root and this image is root-only by design
# (previously the desktop ran as non-root `abc`, so menu clicks worked).
# Replace /usr/bin/chromium in place: the XFCE menu launches it by absolute
# path (Exec=/usr/bin/chromium), so a /usr/local/bin shadow would only fix
# the terminal. Manual `pacman -Syu chromium` inside a live container
# restores the stock binary; rebuild re-applies this.
RUN mv /usr/bin/chromium /usr/bin/chromium.real && \
    printf '%s\n' \
      '#!/bin/sh' \
      '# See NOTE above: root + Chromium sandbox are incompatible.' \
      'for b in /usr/bin/chromium.real /usr/bin/chromium-browser /opt/chromium/chromium; do' \
      '    [ -x "$b" ] && exec "$b" --no-sandbox "$@"' \
      'done' \
      'echo "chromium: real binary not found" >&2' \
      'exit 127' \
      > /usr/bin/chromium && \
    chmod 0755 /usr/bin/chromium

# USER root

RUN bun --version && \
    bunx --version && \
    python --version && \
    chromium --version && \
    fresh --version && \
    opencode --version && \
    vp --version && \
    obscura --version

COPY config/opencode.json /root/.config/opencode/opencode.json
COPY config/cli.json /root/.config/opencode/cli.json
COPY config/AGENTS.md /root/.config/opencode/AGENTS.md

EXPOSE 10100-10110

WORKDIR /workspace

# NOTE: CMD intentionally left unset. ENTRYPOINT is LinuxServer /init (s6).
# Pass `bash` at `run` time for a foreground shell (GUI stays backgrounded):
#   docker run -it --rm ... image bash
# Setting a default `CMD ["bash"]` would make bare `run -d ... image`
# (no tty) exit immediately, breaking detached GUI/background use.
# NOTE: inner Docker (DinD) is preinstalled via the WebTop base
# (dockerd + svc-docker, START_DOCKER=true by default). It starts only
# with --privileged (s6 gate: /dev/cpu_dma_latency) plus a named volume
# at /var/lib/docker (overlay-on-overlay fails without it).
