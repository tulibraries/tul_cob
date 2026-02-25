# BL-1966 Centralize Authentication and API Configuration Checklist

Date: 2026-02-23

## Goal

Move integration auth/config to Rails credentials with a safe staged rollout, no production outage risk, and coordinated cleanup in the separate infra repo.

## Delivery strategy

1. Credentials-first readers with fallback to current config/ENV.
2. QA validation with fallback still available.
3. Production deploy with fallback still available.
4. Infra cleanup (remove deprecated integration env vars from Helm/Vault).
5. App cleanup (remove fallback code + retire legacy config files).

## Commit-sized tasks

### PR A (App): Phase 1 readers and schema

1. Add a single integration config reader module that checks:
   1. `Rails.application.credentials.dig(:integrations, ...)`
   2. existing `Rails.configuration.*` values
   3. direct `ENV[...]` only where still required for compatibility
2. Wire initial call sites:
   1. Alma initializer and JWT decode secret
   2. Primo initializer API key
   3. LibGuides legacy engine key/site id
   4. ArchivesSpace service credentials/timeouts/base URL
3. Add unit specs for reader precedence and fallback behavior.
4. Document credentials key structure for operators.

Exit criteria:

- No behavior regressions in dev/test with no credentials set.
- App boots and core flows still work via legacy sources.

### PR B (App): Expand reader coverage

1. Wire remaining integration call sites to the reader:
   1. QuikPay config access
   2. OCLC config access
   3. SAML/Devise config access points
   4. API cache duration settings if moved under integrations
2. Remove direct `ENV[...]` usage in app code for integration auth keys.
3. Add/update tests around changed code paths.

Exit criteria:

- No integration auth/config values are read directly from `ENV[...]` in app code (except Rails master key path).

### PR C (Infra repo): QA rollout

1. Keep `RAILS_MASTER_KEY` delivery unchanged.
2. Stop injecting deprecated integration env vars in QA only.
3. Keep production env vars unchanged in this PR.
4. Deploy app PR A/B + infra QA changes and run smoke tests.

QA smoke checklist:

- SAML login
- Alma account actions
- Articles/Primo search
- LibGuides panel and endpoint
- Archival Collections (ArchivesSpace)
- QuikPay redirect/callback

Exit criteria:

- QA passes with credentials-only integration config.

### PR D (Infra repo): Production cleanup

1. Deploy app version with readers/fallback already in production.
2. Remove deprecated integration env vars from production Helm/Vault.
3. Verify production smoke tests.

Exit criteria:

- Production functioning with integration config from credentials.

### PR E (App): Hard cleanup

1. Remove fallback branches from reader module.
2. Retire obsolete integration `config/*.yml` files.
3. Remove compatibility notes and update docs.

Exit criteria:

- Credentials are the single source of truth for integrations.

## Proposed credentials structure

```yml
integrations:
  alma:
    apikey:
    auth_secret:
    institution_code:
    delivery_domain:
    timeout: 10
  primo:
    apikey:
    api_base_url:
    scope:
    vid:
    timeout: 3
    retries: 3
  libkey:
    apikey:
    base_url:
    library_id:
    cache_life: PT12H
  lib_guides:
    api_key:
    site_id:
    base_url: https://lgapi-us.libapps.com/1.1/guides
  archives_space:
    base_url: https://scrcarchivesspace.temple.edu/staff/api
    username:
    password:
    open_timeout: 2
    timeout: 5
```

## Guardrails

1. Do not remove production Vault keys before QA verification.
2. Do not remove `RAILS_MASTER_KEY` from Vault/Helm unless platform architecture changes.
3. Avoid a hard cutover until at least one full release validates credentials-first behavior.
