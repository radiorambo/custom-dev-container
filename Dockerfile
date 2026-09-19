FROM archlinux:latest

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    HOME=/root \
    PATH=/root/.local/share/vite-plus/bin:${PATH}

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm --needed \
        base \
        curl \
        git \
        ca-certificates \
        python \
        python-pip \
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
    printf "alias oc='opencode'\nalias npm='bun'\nalias npx='bunx'\n" >> /root/.bashrc

USER root

RUN bun --version && \
    bunx --version && \
    python --version && \
    fresh --version && \
    opencode --version && \
    vp --version && \
    obscura --version && \

COPY config/opencode.json /root/.config/opencode/opencode.json
COPY config/cli.json /root/.config/opencode/cli.json
COPY config/AGENTS.md /root/.config/opencode/AGENTS.md

EXPOSE 10100-10110

WORKDIR /workspace

CMD ["/bin/bash"]
