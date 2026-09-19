FROM archlinux:latest

ARG BUILDER_UID=1000
ARG BUILDER_GID=1000

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    HOME=/root \
    PATH=/root/.local/share/vite-plus/bin:${PATH}

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm --needed \
        base \
        base-devel \
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
    && pacman -Scc --noconfirm

RUN pacman-key --init && \
    pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com && \
    pacman-key --lsign-key 3056513887B78AEB && \
    pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' && \
    pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' && \
    printf '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n' >> /etc/pacman.conf && \
    pacman -Syu fresh-editor paru --noconfirm && \
    pacman -Scc --noconfirm

RUN groupadd --gid "${BUILDER_GID}" builder && \
    useradd --create-home --uid "${BUILDER_UID}" --gid "${BUILDER_GID}" --shell /bin/bash builder && \
    printf 'builder ALL=(ALL) NOPASSWD: ALL\n' > /etc/sudoers.d/builder && \
    chmod 0440 /etc/sudoers.d/builder

USER builder

RUN HOME=/home/builder paru -S --noconfirm --needed obscura-browser-bin

USER root

RUN rm -rf /home/builder/.cache/paru /etc/sudoers.d/builder && \
    curl -fsSL https://vite.plus | VP_NODE_MANAGER=no bash && \
    printf "alias oc='opencode'\n" >> /root/.bashrc

USER root

RUN bun --version && \
    bunx --version && \
    python --version && \
    fresh --version && \
    opencode --version && \
    vp --version && \
    obscura --version

COPY config/opencode.json /root/.config/opencode/opencode.json
COPY config/cli.json /root/.config/opencode/cli.json
COPY config/AGENTS.md /root/.config/opencode/AGENTS.md

EXPOSE 10100-10110

EXPOSE 10100-10110

WORKDIR /workspace

CMD ["/bin/bash"]
