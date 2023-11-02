// See the shakacode/shakapacker README and docs directory for advice on customizing your webpackConfig.
const { generateWebpackConfig, merge } = require('shakapacker')

const webpackConfig = generateWebpackConfig()

const options = {
  resolve: {
    extensions: ['.css', '.scss'],
    alias: {
      jquery: 'jquery/src/jquery',
    }
  }
}

module.exports = merge(options, webpackConfig)
