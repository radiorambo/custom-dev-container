FROM archlinux:latest

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm --needed \
        base \
        curl \
        git \
        ca-certificates \
        python \
        python-pip \
        opencode \
        unzip \
        xz \
        which \
        sudo \
    && pacman -Scc --noconfirm

RUN pacman-key --init && \
    pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com && \
    pacman-key --lsign-key 3056513887B78AEB && \
    pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' && \
    pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' && \
    printf '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n' >> /etc/pacman.conf && \
    pacman -Syu fresh-editor --noconfirm && \
    pacman -Scc --noconfirm

RUN set -eux; \
    bun_arch=$([ "$(uname -m)" = "x86_64" ] && echo x64 || echo aarch64); \
    bun_url=$(curl -fsSL https://api.github.com/repos/oven-sh/bun/releases/latest \
      | python -c "import json,sys; print([a['browser_download_url'] for a in json.load(sys.stdin)['assets'] if a['name'].endswith(f'bun-linux-${bun_arch}.zip')][0])"); \
    curl -fsSL -o /tmp/bun.zip "$bun_url"; \
    unzip /tmp/bun.zip -d /tmp/bun; \
    install -m 0755 /tmp/bun/bun-linux-${bun_arch}/bun /usr/local/bin/bun; \
    ln -s bun /usr/local/bin/bunx; \
    rm -rf /tmp/bun /tmp/bun.zip

RUN bun --version && \
    bunx --version && \
    python --version && \
    fresh --version && \
    opencode --version

# OpenCode config: enable "YOLO mode" (all permissions allowed, no prompts).
RUN mkdir -p /root/.config/opencode && \
    cat > /root/.config/opencode/opencode.json <<'EOF'
{
  "$schema": "https://opencode.ai/config.json",
  "permission": "allow",
  "autoupdate": false
}
EOF

WORKDIR /workspace

CMD ["/bin/bash"]