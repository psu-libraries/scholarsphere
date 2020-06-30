// Load our local stylesheets
import './styles'

// Load any additional custom javascript code here...
import './view_statistics_chart'

// Load images
// Retrieve the path to the image via <%= image_pack_tag('image.png') %>
require.context('./images/', true)
