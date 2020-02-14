# 5. Order files alphanumerically

Date: 2020-02-14

## Status

Accepted

## Context

Files within a work should be displayed in a certain order. The ordering can be automatic or arbitrary.

## Decision

Files will be ordered alphanumerically, according to their names. The application can now render them in the same order
everytime, without additional metadata.

## Consequences

Arbitrary ordering will not be supported. Users will not be able to put their files in a specific order and have that
order persisted in the application.
