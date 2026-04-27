import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { resolve } from "node:path";

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      "@music/core": resolve(__dirname, "../../packages/core/src/index.ts"),
      "@music/ui": resolve(__dirname, "../../packages/ui/src/index.tsx")
    }
  },
  server: {
    port: 3000,
    host: true,
    allowedHosts: ["musicrr.haasele.dev", ".haasele.dev"]
  }
});
