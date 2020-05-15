// Load Blacklight's stylesheet assets
import './styles'

// Load Blacklight's dependencies. These must be required first.
require('popper.js/dist/umd/popper')
require('bootstrap/dist/js/bootstrap')
require('twitter-typeahead-rails/vendor/assets/javascripts/twitter/typeahead/typeahead.bundle')

// Load Blacklight's javascript assets
// Require each one individually because each script may have its own
// import, as opposed to:
//   require('blacklight-frontend/app/assets/javascripts/blacklight/blacklight')
require('blacklight-frontend/app/javascript/blacklight/core')
require('blacklight-frontend/app/javascript/blacklight/autocomplete')
require('blacklight-frontend/app/javascript/blacklight/checkbox_submit')
require('blacklight-frontend/app/javascript/blacklight/modal')
require('blacklight-frontend/app/javascript/blacklight/bookmark_toggle')
// This was removed from the repo and apparently is no longer needed?
// require('blacklight-frontend/app/javascript/blacklight/collapsable')
require('blacklight-frontend/app/javascript/blacklight/facet_load')
require('blacklight-frontend/app/javascript/blacklight/search_context')
