import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { resolve } from "node:path";
import { readFileSync } from "node:fs";

const tlsCertPath = process.env.TLS_CERT_PATH?.trim() || "/run/certs/origin-cert.pem";
const tlsKeyPath = process.env.TLS_KEY_PATH?.trim() || "/run/certs/origin-key.pem";
const tlsEnabled = process.env.VITE_TLS !== "0";
const webPort = Number(process.env.VITE_PORT ?? process.env.WEB_HTTPS_PORT ?? "9443");

function getHttpsConfig() {
  if (!tlsEnabled) return undefined;
  try {
    return {
      cert: readFileSync(tlsCertPath),
      key: readFileSync(tlsKeyPath)
    };
  } catch (err) {
    const details = err instanceof Error ? err.message : String(err);
    throw new Error(`TLS enabled but certificate files are not readable (${tlsCertPath}, ${tlsKeyPath}): ${details}`);
  }
}

export default defineConfig(({ command }) => ({
  plugins: [react()],
  resolve: {
    alias: {
      "@music/core": resolve(__dirname, "../../packages/core/src/index.ts"),
      "@music/ui": resolve(__dirname, "../../packages/ui/src/index.tsx")
    }
  },
  server: {
    port: Number.isFinite(webPort) ? webPort : 9443,
    host: true,
    strictPort: true,
    https: command === "serve" ? getHttpsConfig() : undefined,
    allowedHosts: ["musicrr.haasele.dev", ".haasele.dev"],
    proxy: {
      "/api": {
        target: "http://musicrr-api:3001",
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api/, "")
      },
      "/events": {
        target: "ws://musicrr-api:3001",
        ws: true,
        changeOrigin: true
      }
    }
  }
}));
