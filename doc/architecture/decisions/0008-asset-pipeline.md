# 8. Asset Pipeline

Date: 2020-05-18

## Status

Accepted

## Context

We were unable to address a security vulnerability in jQuery because we couldn't update Bootstrap. This was due to the
fact that it was present as both a gem and an npm package.

## Decision

We removed asset pipeline completely and moved all css and image assets to webpacker. This allowed us to update jQuery
via yarn.

## Consequences

For any gems that include stylesheets or images, we will need to include them as a yarn dependency so that the repo is
installed to node_modules. We're currently doing this with typeahead twitter.
