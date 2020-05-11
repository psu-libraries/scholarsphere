# 7. Published Date Field

Date: 2020-05-11

## Status

Accepted

## Context

The field for _Published Date_ is a free-text field, but also needs to be expressed as a date. Scholarsphere 3 has
entries that cannot be mapped to actual dates, so we need a way to store non-parseable dates but also have some kind of
validation as well.

## Decision

Published date will only be validate at the UI and API level. The database will not validate any of the entries. This
allows us to store anything when migrating, or creating records through means other that the API or UI. When values are
entered through the API or UI, an EDTF date must be used.

## Consequences

The "bad" date data is still there, but moving forward, there shouldn't be any more of it.
