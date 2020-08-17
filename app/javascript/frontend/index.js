// Load dependencies
// Load styles
import './styles'

// View statistics
import './scripts/view_statistics_chart'

require('jquery/dist/jquery')
require('bootstrap/dist/js/bootstrap')

// Load images
// Retrieve the path to the image via <%= image_pack_tag('image.png') %>
require.context('./img/', true)
