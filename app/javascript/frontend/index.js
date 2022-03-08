// Load dependencies
// Load styles
import './styles'

// View statistics
import './scripts/view_statistics_chart'

// Thumbnail selection settings
import './scripts/thumbnail_selection_init'

// Load dependencies
require('jquery/dist/jquery')
require('bootstrap/dist/js/bootstrap')
require('select2/dist/js/select2')

// Load Blacklight dependencies
// This should be just enough JS to get the facet modals working.
require('blacklight-frontend/app/javascript/blacklight/core')
require('blacklight-frontend/app/javascript/blacklight/modal')
require('blacklight-frontend/app/javascript/blacklight/facet_load')

// Load images
// Retrieve the path to the image via <%= image_pack_tag('image.png') %>
require.context('./img/', true)

// Initialize tooltips
$(function () {
  $('[data-toggle="tooltip"]').tooltip()
})
