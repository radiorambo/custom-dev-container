FROM archlinux:latest

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm --needed \
        base \
        curl \
        wget \
        git \
        ca-certificates \
        nodejs \
        npm \
        python \
        python-pip \
        unzip \
        xz \
        which \
        sudo \
    && pacman -Scc --noconfirm

RUN set -eux; \
    bun_arch=$([ "$(uname -m)" = "x86_64" ] && echo x64 || echo aarch64); \
    bun_url=$(curl -fsSL https://api.github.com/repos/oven-sh/bun/releases/latest \
      | python -c "import json,sys; print([a['browser_download_url'] for a in json.load(sys.stdin)['assets'] if a['name'].endswith(f'bun-linux-${bun_arch}.zip')][0])"); \
    curl -fsSL -o /tmp/bun.zip "$bun_url"; \
    unzip /tmp/bun.zip -d /tmp/bun; \
    install -m 0755 /tmp/bun/bun-linux-${bun_arch}/bun /usr/local/bin/bun; \
    rm -rf /tmp/bun /tmp/bun.zip

RUN set -eux; \
    fresh_arch=$([ "$(uname -m)" = "x86_64" ] && echo x86_64 || echo aarch64); \
    fresh_url=$(curl -fsSL https://api.github.com/repos/sinelaw/fresh/releases/latest \
      | python -c "import json,sys; print([a['browser_download_url'] for a in json.load(sys.stdin)['assets'] if a['name']==f'fresh-editor-${fresh_arch}-unknown-linux-gnu.tar.xz'][0])"); \
    curl -fsSL -o /tmp/fresh.tar.xz "$fresh_url"; \
    tar -xJf /tmp/fresh.tar.xz -C /tmp; \
    install -m 0755 /tmp/fresh-editor-${fresh_arch}-unknown-linux-gnu/fresh /usr/local/bin/fresh; \
    rm -rf /tmp/fresh-editor-* /tmp/fresh.tar.xz

RUN node --version && \
    bun --version && \
    python --version && \
    fresh --version

WORKDIR /workspace

CMD ["/bin/bash"]