// Load dependencies
// Load styles
import './styles'

require('jquery/dist/jquery')
require('bootstrap/dist/js/bootstrap')

// View statistics
import './scripts/view_statistics_chart'

// Load images
// Retrieve the path to the image via <%= image_pack_tag('image.png') %>
require.context('./img/', true)
