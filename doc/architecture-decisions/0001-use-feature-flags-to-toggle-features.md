# 1. Use feature flags to toggle features

Date: 2018-03-29

## Status

Accepted

## Context

There are features that exist in the codebase we are not yet ready to release in production. We would like to use feature flags to toggle the availability of certain features, which will help prevent development and production branches from drifting.

## Decision

We've decided to implement very simple feature flags that can be toggled with environment variables.

## Consequences

Deployments that want to toggle off a feature are more complex, and now we need to more tightly couple our merging PRs with deployments.
