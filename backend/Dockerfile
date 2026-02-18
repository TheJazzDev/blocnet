# ── Stage 1: Build ────────────────────────────────────────────────────────────
FROM oven/bun:1.2 AS builder

WORKDIR /app

# Copy prisma schema BEFORE install so postinstall (prisma generate) can find it
COPY package.json bun.lock ./
COPY prisma ./prisma

RUN bun install --frozen-lockfile

# Copy remaining source
COPY . .

# Build NestJS (prisma generate already ran in postinstall)
RUN bun run build

# ── Stage 2: Production image ──────────────────────────────────────────────────
FROM oven/bun:1.2-slim AS runner

WORKDIR /app

ENV NODE_ENV=production

# Install OpenSSL required by Prisma
RUN apt-get update -y && apt-get install -y openssl && rm -rf /var/lib/apt/lists/*

# Only copy what's needed to run
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/prisma.config.ts ./prisma.config.ts
COPY --from=builder /app/package.json ./package.json

# Run migrations then start the server
CMD bunx prisma migrate deploy && node dist/main
