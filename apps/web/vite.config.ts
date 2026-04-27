import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { resolve } from "node:path";
import { existsSync, readFileSync, readdirSync } from "node:fs";

const tlsCertPath = process.env.TLS_CERT_PATH?.trim() || "";
const tlsKeyPath = process.env.TLS_KEY_PATH?.trim() || "";
const tlsEnabled = process.env.VITE_TLS !== "0";
const webPort = Number(process.env.VITE_PORT ?? process.env.WEB_HTTPS_PORT ?? "9443");

function pickExistingPath(candidates: string[]): string | null {
  for (const p of candidates) {
    if (p && existsSync(p)) return p;
  }
  return null;
}

function getHttpsConfig() {
  if (!tlsEnabled) return undefined;
  const certCandidates = [
    tlsCertPath,
    "/run/certs/origin-cert.pem",
    "/run/certs/cert.pem",
    "/run/certs/fullchain.pem"
  ];
  const keyCandidates = [
    tlsKeyPath,
    "/run/certs/origin-key.pem",
    "/run/certs/key.pem",
    "/run/certs/privkey.pem"
  ];
  const resolvedCertPath = pickExistingPath(certCandidates);
  const resolvedKeyPath = pickExistingPath(keyCandidates);
  if (!resolvedCertPath || !resolvedKeyPath) {
    let certDirEntries = "unavailable";
    try {
      certDirEntries = readdirSync("/run/certs").join(", ");
    } catch {
      // ignore
    }
    throw new Error(
      `TLS enabled but cert/key not found. looked cert=[${certCandidates.join(", ")}] key=[${keyCandidates.join(", ")}], /run/certs contains: ${certDirEntries}`
    );
  }
  try {
    return {
      cert: readFileSync(resolvedCertPath),
      key: readFileSync(resolvedKeyPath)
    };
  } catch (err) {
    const details = err instanceof Error ? err.message : String(err);
    throw new Error(
      `TLS enabled but certificate files are not readable (${resolvedCertPath}, ${resolvedKeyPath}): ${details}`
    );
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
