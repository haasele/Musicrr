import type { Config } from "tailwindcss";

export default {
  content: ["./index.html", "./src/**/*.{ts,tsx}", "../../packages/ui/src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      animation: {
        "spin-slow": "spin 12s linear infinite"
      }
    }
  },
  plugins: []
} satisfies Config;
