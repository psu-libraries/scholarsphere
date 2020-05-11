# 6. Public Discovery Access

Date: 2020-05-11

## Status

Accepted

## Context

Metadata for works and collections should be publicly viewable. Only the binary content, i.e. the files, within the
work needs to be restricted based on visibility or other permissions.

## Decision

Grant discovery access to the public on all works and collections by creating the appropriate ACL for each work and
collection. Discovery access stipulates that all metadata is viewable, but that binary content is not downloadable.

## Consequences

Because access is controlled by the ACL, we can restrict individual works and collections later, if needed. It also
requires an additional ACL record per resource.
