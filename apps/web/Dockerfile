FROM oven/bun:1

WORKDIR /app

COPY package.json bun.lock ./
COPY apps/web/package.json ./apps/web/package.json
COPY packages/core/package.json ./packages/core/package.json
COPY packages/ui/package.json ./packages/ui/package.json

RUN bun install

COPY . .

RUN rm -rf apps/web/node_modules packages/core/node_modules packages/ui/node_modules && bun install

EXPOSE 3000

CMD ["bun", "run", "--cwd", "apps/web", "dev", "--host", "0.0.0.0", "--port", "3000"]
