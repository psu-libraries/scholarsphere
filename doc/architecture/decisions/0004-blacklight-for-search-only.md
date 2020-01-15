# 4. blacklight-for-search-only

Date: 2020-01-15

## Status

Accepted

## Context

There are two ways we can display works and work versions in Scholarsphere: 1) using the record that is in the 
Postgres database; or, 2) using the record that is in Solr.

## Decision

We going to use the Postgres record for displaying individual records, leaving Blacklight's Solr record for displaying
search results only. The Solr record, or SolrDocument, will not be used when displaying the detailed record for a
work or work version. It will only be used within the context of a list of search results.

## Consequences

Blacklight dependency footprint is reduced, i.e. we're relying on it to do less. However, we also loose some baked-in
features such as json API displays and other methods of reformating existing records, such as xml views, etc. That
doesn't mean we can't re-use them later.
