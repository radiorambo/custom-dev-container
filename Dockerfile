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
        nodejs-lts \
        pnpm \
        npm \
        bun \
        opencode \
        unzip \
        xz \
        which \
        sudo \
        jq \
        chromium \
    && pacman -Scc --noconfirm

RUN pacman-key --init && \
    pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com && \
    pacman-key --lsign-key 3056513887B78AEB && \
    pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' && \
    pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' && \
    printf '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n' >> /etc/pacman.conf && \
    pacman -Syu fresh-editor --noconfirm && \
    pacman -Scc --noconfirm

RUN npm install -g chrome-devtools-mcp

RUN curl -fsSL https://vite.plus | VP_NODE_MANAGER=no bash

# ponytail: split layout reports bin at ~/.local/share/vite-plus/bin
ENV PATH="/root/.local/share/vite-plus/bin:${PATH}"

RUN printf "alias oc='opencode'\n" >> /root/.bashrc

RUN bun --version && \
    bunx --version && \
    python --version && \
    fresh --version && \
    opencode --version && \
    vp --version && \
    chrome-devtools-mcp --version

COPY config/opencode.json /root/.config/opencode/opencode.json
COPY config/AGENTS.md /root/.config/opencode/AGENTS.md

EXPOSE 10100-10110

EXPOSE 10100-10110

WORKDIR /workspace

CMD ["/bin/bash"]
