// eslint.config.js
const { defineConfig } = require("eslint/config");

module.exports = defineConfig([
  {
    files: ['**/*.js'],
    languageOptions: {
      ecmaVersion: 2025,
      sourceType: 'module',
      globals: {
        Atomics: 'readonly',
        SharedArrayBuffer: 'readonly'
      },
    },
    plugins: {
      // Add plugins here if needed
    },
    rules: {
      indent: [
        'error',
        2,
        {
          flatTernaryExpressions: true,
          SwitchCase: 1
        }
      ]
    }
  }
])
