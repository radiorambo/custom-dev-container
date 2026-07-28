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
        which \
        sudo \
    && pacman -Scc --noconfirm

RUN curl -fsSL https://bun.sh/install | bash && \
    cp /root/.bun/bin/bun /usr/local/bin/bun && \
    chmod +x /usr/local/bin/bun

RUN curl -fsSL https://raw.githubusercontent.com/sinelaw/fresh-editor/main/install.sh | sh && \
    mv /root/.local/bin/fresh /usr/local/bin/fresh && \
    chmod +x /usr/local/bin/fresh

RUN ln -sf /usr/bin/python /usr/local/bin/python3

RUN node --version && \
    bun --version && \
    python --version && \
    fresh --version || true

WORKDIR /workspace

CMD ["/bin/bash"]