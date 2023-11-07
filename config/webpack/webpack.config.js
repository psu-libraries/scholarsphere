// See the shakacode/shakapacker README and docs directory for advice on customizing your webpackConfig.
const { generateWebpackConfig, inliningCss, merge } = require('shakapacker');
const webpackConfig = generateWebpackConfig()
const isDevelopment = process.env.NODE_ENV !== 'production';

const options = {
  resolve: {
    extensions: ['.css', '.scss'],
    alias: {
      jquery: 'jquery/src/jquery',
    }
  },
  mode: isDevelopment ? 'development' : 'production'
};

if (isDevelopment && inliningCss) {
  const ReactRefreshWebpackPlugin = require('@pmmmwh/react-refresh-webpack-plugin');

  webpackConfig.plugins.push(
    new ReactRefreshWebpackPlugin({
      overlay: {
        sockPort: webpackConfig.devServer.port,
      },
    })
  );
}

module.exports = merge(options, webpackConfig)
