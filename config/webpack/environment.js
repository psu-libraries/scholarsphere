const { environment } = require('shakapacker')
const webpack = require('webpack')

environment.plugins.prepend(
  'Provide',
  new webpack.ProvidePlugin({
    Popper: ['popper.js', 'default']
  })
)

module.exports = environment
