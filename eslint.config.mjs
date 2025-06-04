import js from "@eslint/js";
import globals from "globals";
import { defineConfig } from "eslint/config";
import babelParser from "@babel/eslint-parser";


export default defineConfig([
  {
    files: ["**/*.{js,mjs,cjs}"],
    plugins: { js },
    extends: ["js/recommended"],
    languageOptions: {
      parser: babelParser,
      ecmaVersion: 2024,
      sourceType: "module",
      globals: {
        ...globals.browser,
        $: "readonly",
        jQuery: "readonly",
        Atomics: "readonly",
        SharedArrayBuffer: "readonly",
        require: "readonly"
      }
    },
    rules: {
      indent: [
        "error",
        2,
        {
          flatTernaryExpressions: true,
          SwitchCase: 1
        }
      ],
      "no-unused-vars": ["error", { "argsIgnorePattern": "^_" }]
    }
  },
  {
    files: ["**/*.test.js", "**/*.spec.js", "**/*.test.mjs", "**/*.spec.mjs"],
    languageOptions: {
      globals: {
        ...globals.jest
      }
    }
  }
]);
