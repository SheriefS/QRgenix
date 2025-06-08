import js from "@eslint/js";
import globals from "globals";
import tseslint from "typescript-eslint";
import pluginReact from "eslint-plugin-react";
import { defineConfig } from "eslint/config";

export default defineConfig([
  {
    files: ["**/*.{js,mjs,cjs,ts,mts,cts,jsx,tsx}"],
    plugins: {
      js,
      react: pluginReact
    },
    extends: ["js/recommended"],
    languageOptions: {
      ecmaVersion: "latest",
      sourceType: "module",
      globals: {
        ...globals.browser,
        ...globals.node
      },
    },
    rules: {
      ...js.configs.recommended.rules,
      ...pluginReact.configs.recommended.rules,
      ...pluginReact.configs["jsx-runtime"].rules,

      "react/prop-types": "off",
      "react/react-in-jsx-scope": "off",
      "no-undef": "error",
    },
  },
  tseslint.configs.recommended,
  tseslint.configs.recommendedTypeChecked,
  pluginReact.configs.flat.recommended,
  pluginReact.configs.flat["jsx-runtime"],
]);
