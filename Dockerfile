FROM archlinux:latest

ARG USER_UID=1000
ARG USER_GID=1000

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    HOME=/home/user \
    PATH=/home/user/.local/share/vite-plus/bin:${PATH}

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

RUN groupadd --gid "${USER_GID}" user && \
    useradd --create-home --uid "${USER_UID}" --gid "${USER_GID}" --shell /bin/bash user && \
    printf 'user ALL=(ALL) NOPASSWD: ALL\n' > /etc/sudoers.d/user && \
    chmod 0440 /etc/sudoers.d/user

USER user

RUN paru -S --noconfirm --needed obscura-browser-bin && \
    curl -fsSL https://vite.plus | VP_NODE_MANAGER=no bash && \
    printf "alias oc='opencode'\n" >> /home/user/.bashrc

USER root

RUN rm -rf /home/user/.cache/paru /etc/sudoers.d/user

USER user

RUN bun --version && \
    bunx --version && \
    python --version && \
    fresh --version && \
    opencode --version && \
    vp --version && \
    obscura --version

COPY --chown=user:user config/opencode.json /home/user/.config/opencode/opencode.json
COPY --chown=user:user config/cli.json /home/user/.config/opencode/cli.json
COPY --chown=user:user config/AGENTS.md /home/user/.config/opencode/AGENTS.md

EXPOSE 10100-10110

EXPOSE 10100-10110

WORKDIR /workspace

CMD ["/bin/bash"]
