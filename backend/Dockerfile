# ── Stage 1: Build ────────────────────────────────────────────────────────────
FROM oven/bun:1.2 AS builder

WORKDIR /app

# Install dependencies
COPY package.json bun.lock ./
RUN bun install --frozen-lockfile

# Copy source
COPY . .

# Generate Prisma client then build NestJS
RUN bunx prisma generate
RUN bun run build

# ── Stage 2: Production image ──────────────────────────────────────────────────
FROM oven/bun:1.2-slim AS runner

WORKDIR /app

ENV NODE_ENV=production

# Only copy what's needed to run
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/package.json ./package.json

# Run migrations then start the server
CMD bunx prisma migrate deploy && node dist/main
