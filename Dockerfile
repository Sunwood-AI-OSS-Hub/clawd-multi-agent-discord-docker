FROM node:22-bookworm

# Install Bun (required for build scripts)
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

RUN corepack enable

WORKDIR /app

ARG OPENCLAW_DOCKER_APT_PACKAGES=""
RUN if [ -n "$OPENCLAW_DOCKER_APT_PACKAGES" ]; then \
      apt-get update && \
      DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $OPENCLAW_DOCKER_APT_PACKAGES && \
      apt-get clean && \
      rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*; \
    fi

COPY openclaw/package.json openclaw/pnpm-lock.yaml openclaw/pnpm-workspace.yaml openclaw/.npmrc ./
COPY openclaw/ui/package.json ./ui/package.json
COPY openclaw/patches ./patches
COPY openclaw/scripts ./scripts

# Use HTTPS for git protocol to avoid local .git dependency
RUN echo "git-protocol=https" >> .npmrc

RUN pnpm install --frozen-lockfile

COPY openclaw/. .
RUN pnpm build
# Force pnpm for UI build (Bun may fail on ARM/Synology architectures)
ENV OPENCLAW_PREFER_PNPM=1
RUN pnpm ui:install
RUN pnpm ui:build

ENV NODE_ENV=production

CMD ["node", "dist/index.js"]
