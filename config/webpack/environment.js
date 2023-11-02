const { environment } = require('@rails/webpacker')
const webpack = require('webpack')

environment.plugins.prepend(
  'Provide',
  new webpack.ProvidePlugin({
    Popper: ['popper.js', 'default']
  })
)


module.exports = environment
