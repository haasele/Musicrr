FROM oven/bun:1.2.14

WORKDIR /app

COPY package.json bun.lock ./
COPY apps/api/package.json ./apps/api/package.json
COPY packages/core/package.json ./packages/core/package.json
COPY packages/crypto/package.json ./packages/crypto/package.json
COPY packages/importer/package.json ./packages/importer/package.json

RUN bun install

COPY . .

RUN rm -rf apps/api/node_modules packages/core/node_modules packages/crypto/node_modules packages/importer/node_modules && bun install

EXPOSE 3001

CMD ["bun", "run", "apps/api/src/index.ts"]
