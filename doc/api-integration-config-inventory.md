# API Integration Config Inventory (BL-1966 Baseline)

Date: 2026-02-23
Branch: `BL-1949-add-bookmark-all-functionality`

## Scope

This inventory captures external API/auth integrations currently configured through `config/*.yml`, direct `ENV[...]`, or hardcoded values in app code.

## Current config loading pattern

`config/application.rb` loads integration configs via `config_for` into:

- `Rails.configuration.alma`
- `Rails.configuration.bento`
- `Rails.configuration.cdm`
- `Rails.configuration.oclc`
- `Rails.configuration.lib_guides`
- `Rails.configuration.devise`
- `Rails.configuration.caches`
- `Rails.configuration.quik_pay`

Main references: `config/application.rb:41`, `config/application.rb:42`, `config/application.rb:43`, `config/application.rb:45`, `config/application.rb:46`, `config/application.rb:47`, `config/application.rb:48`, `config/application.rb:50`.

## Integration inventory

| Integration | Code entrypoints | Current config source | Secret values | Non-secret values | Current ENV usage | Cache / timeout / retry behavior | Proposed credentials path |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Alma API + Alma auth secret | `config/initializers/alma.rb:3`, `app/controllers/sessions/social_login.rb:11` | `config/alma.yml:1` -> `Rails.configuration.alma`; initializer also writes to `ENV` | `apikey`, `auth_secret` | `institution_code`, `delivery_domain`, `timeout` | `ALMA_API_KEY`, `ALMA_AUTH_SECRET`, `ALMA_INSTITUTION_CODE`, `ALMA_DELIVERY_DOMAIN` | Alma client timeout from config (`alma.timeout`) | `integrations.alma.apikey`, `integrations.alma.auth_secret`, `integrations.alma.institution_code`, `integrations.alma.delivery_domain`, `integrations.alma.timeout` |
| Alma OAI harvest | `lib/oai/alma.rb:21` | Hardcoded URL in code | none | OAI base URL, set name, metadataPrefix | none | `HTTParty.get(..., timeout: 120)` | `integrations.alma_oai.base_url`, `integrations.alma_oai.set`, `integrations.alma_oai.metadata_prefix` |
| Primo API | `config/initializers/primo.rb:3`, `app/models/blacklight/primo_central/repository.rb:15` | `config/initializers/primo.rb` uses `ENV["PRIMO_API_KEY"]` fallback to `Rails.configuration.bento.primo.apikey` (`config/bento.yml`) | `apikey` | `api_base_url`, `scope`, `vid`, `web_ui_base_url`, timeout/retry settings | `PRIMO_API_KEY` | Primo gem configured with `timeout=3`, retries enabled (`retries=3`); search results cached via `Rails.cache` in repository | `integrations.primo.apikey`, `integrations.primo.api_base_url`, `integrations.primo.scope`, `integrations.primo.vid`, `integrations.primo.web_ui_base_url`, `integrations.primo.timeout`, `integrations.primo.retries` |
| LibKey / BrowZine | `app/models/solr_document.rb:204`, `app/models/blacklight/primo_central/document.rb:160` | `config/bento.yml:11` (`libkey` section) and `config/caches.yml:4` for cache life | `libkey.apikey` | `libkey.base_url`, `libkey.library_id`, cache duration | `LIBKEY_ARTICLE_CACHE_LIFE` (via `config/caches.yml`) | Timeout 2s (journal), 4s (article); article lookup cached with `libkey_article_cache_life` | `integrations.libkey.apikey`, `integrations.libkey.base_url`, `integrations.libkey.library_id`, `integrations.libkey.cache_life` |
| LibGuides (service object path) | `app/models/lib_guides_api.rb:22`, `app/controllers/lib_guides_controller.rb:4` | `config/lib_guides.yml:1` -> `Rails.configuration.lib_guides` | `api_key` | `site_id`, host/path currently hardcoded in model | `LIB_GUIDES_API_KEY`, `LIB_GUIDES_SITE_ID` | No explicit timeout/retry in `HTTParty.get` | `integrations.lib_guides.api_key`, `integrations.lib_guides.site_id`, `integrations.lib_guides.base_url` |
| LibGuides (legacy bento engine path) | `app/search_engines/bento_search/lib_guides_engine.rb:9` | Direct hardcoded URL + direct `ENV["LIB_GUIDES_API_KEY"]`; hardcoded `site_id: 17` | `LIB_GUIDES_API_KEY` | API URL, site id | `LIB_GUIDES_API_KEY` | No timeout/retry | Same as above; remove direct `ENV` and hardcoded `site_id` |
| CONTENTdm | `app/search_engines/bento_search/cdm_engine.rb:54`, `app/search_engines/bento_search/cdm_engine.rb:140` | `config/cdm_collection.yml:1` and locale key `config/locales/en.yml:307` for base URL | none | `collection_ids`, base URL | none | GET timeout/open_timeout; retries via local `with_retries`; collection list cached 1 day | `integrations.cdm.base_url`, `integrations.cdm.collection_ids`, `integrations.cdm.timeouts`, `integrations.cdm.retries` |
| QuikPay | `app/controllers/concerns/quik_pay.rb:25` | `config/quik_pay.yml:1` -> `Rails.configuration.quik_pay` | `secret` | `redirect_url`, `url` | `QUIK_PAY_SECRET`, `QUIK_PAY_REDIRECT_URL`, `QUIK_PAY_URL` | No network timeout defined in app (redirect-based flow) | `integrations.quik_pay.secret`, `integrations.quik_pay.redirect_url`, `integrations.quik_pay.url` |
| OCLC citations (planned removal in BL-1970) | `app/models/citation.rb:58` | `config/oclc.yml:1` -> `Rails.configuration.oclc` | `apikey` | `base_url`, `citation_formats` | `OCLC_WS_KEY` | `HTTParty.get` with error rescue; no explicit timeout | `integrations.oclc.apikey`, `integrations.oclc.base_url`, `integrations.oclc.citation_formats` |
| ArchivesSpace | `app/services/archives_space_service.rb:8`, `app/search_engines/bento_search/archival_collections_engine.rb:16` | Service defines constants from direct `ENV.fetch` and hardcoded `BASE_URL` | `USERNAME`, `PASSWORD` | `BASE_URL`, `OPEN_TIMEOUT`, `TIMEOUT` | `ARCHIVESSPACE_USER`, `ARCHIVESSPACE_PASSWORD`, `ARCHIVESSPACE_OPEN_TIMEOUT`, `ARCHIVESSPACE_TIMEOUT` | Session token cached; retries once on 401/403 by token refresh | `integrations.archives_space.username`, `integrations.archives_space.password`, `integrations.archives_space.base_url`, `integrations.archives_space.open_timeout`, `integrations.archives_space.timeout` |
| Devise SAML / IdP | `config/initializers/devise.rb:254`, `config/devise.yml:1`, `app/controllers/application_controller.rb:38` | `config/devise.yml` loaded as `Rails.configuration.devise`; runtime fetch of remote metadata URL | `saml_private_key` (certificate is public but sensitive), optional metadata auth values | issuer, ACS URL, IdP metadata URL, IdP SSO URL, signout redirect URL | `IDP_REDIRECT_URL`, `COB_SP_CERT`, `COB_SP_KEY`, `COB_SAML_ISSUER`, `COB_SAML_ASSERTION_CONSUMER_SERVICE_URL`, `COB_SAML_IDP_METADATA_URL`, `COB_SAML_IDP_SSO_SERVICE_URL` | Boot-time remote metadata call; SSL failures can fail boot outside test | `integrations.saml.sign_out_redirect_url`, `integrations.saml.certificate`, `integrations.saml.private_key`, `integrations.saml.issuer`, `integrations.saml.acs_url`, `integrations.saml.idp_metadata_url`, `integrations.saml.idp_sso_service_url` |
| Manifold alerts JSON | `app/controllers/application_controller.rb:51` | Hardcoded URL in controller | none | alerts URL | none | `HTTParty.get(..., timeout: 1)`; cached 5 minutes | `integrations.manifold.alerts_url`, `integrations.manifold.timeout`, `integrations.manifold.cache_life` |

## Config files implicated in BL-1966

Primary files to replace or retire:

- `config/alma.yml`
- `config/bento.yml`
- `config/lib_guides.yml`
- `config/cdm_collection.yml`
- `config/quik_pay.yml`
- `config/oclc.yml`
- `config/devise.yml`
- `config/caches.yml` (if API-specific cache durations are moved with integration config)

Other files needing code changes:

- `config/initializers/alma.rb` (remove ENV backfill side effects)
- `config/initializers/primo.rb` (single source of truth for API key)
- `app/controllers/sessions/social_login.rb` (stop direct `ENV["ALMA_AUTH_SECRET"]`)
- `app/search_engines/bento_search/lib_guides_engine.rb` (remove direct ENV + hardcoded site id)
- `app/services/archives_space_service.rb` (replace direct ENV constants)
- `app/controllers/application_controller.rb` (manifold URL to config)

## ENV variable inventory to remove from app config source

These are currently used for integration auth/config in app code:

- `ALMA_API_KEY`
- `ALMA_AUTH_SECRET`
- `ALMA_INSTITUTION_CODE`
- `ALMA_DELIVERY_DOMAIN`
- `PRIMO_API_KEY`
- `LIB_GUIDES_API_KEY`
- `LIB_GUIDES_SITE_ID`
- `LIBKEY_ARTICLE_CACHE_LIFE`
- `QUIK_PAY_SECRET`
- `QUIK_PAY_REDIRECT_URL`
- `QUIK_PAY_URL`
- `OCLC_WS_KEY`
- `ARCHIVESSPACE_USER`
- `ARCHIVESSPACE_PASSWORD`
- `ARCHIVESSPACE_OPEN_TIMEOUT`
- `ARCHIVESSPACE_TIMEOUT`
- `IDP_REDIRECT_URL`
- `COB_SP_CERT`
- `COB_SP_KEY`
- `COB_SAML_ISSUER`
- `COB_SAML_ASSERTION_CONSUMER_SERVICE_URL`
- `COB_SAML_IDP_METADATA_URL`
- `COB_SAML_IDP_SSO_SERVICE_URL`

## Infra handoff notes (separate Helm/Vault repo)

Because charts are in a separate repository, BL-1966 needs a paired infra ticket/PR to:

- Add new encrypted credential material delivery process (if not already present).
- Stop templating the above integration-specific env vars into deployment manifests.
- Remove deprecated secret keys from Vault after app cutover verification.
- Keep only non-integration runtime env vars that remain intentionally environment-driven.

## Suggested migration order for BL-1966

1. Add credentials schema and loader methods (no behavior change yet).
2. Move one integration at a time to credentials with temporary fallback to existing source.
3. Remove direct `ENV[...]` call sites for integration auth.
4. Remove obsolete `config/*.yml` integration files after all readers are cut over.
5. Submit coordinated Helm/Vault cleanup PR in infra repo.

## Implementation status (as of 2026-02-24)

Completed in app code:

- Central reader added and loaded at boot: `lib/integration_config.rb`, `config/application.rb`.
- Credentials-first wiring done for Alma/Primo/LibGuides/ArchivesSpace:
  `config/initializers/alma.rb`, `config/initializers/primo.rb`, `app/controllers/sessions/social_login.rb`,
  `app/search_engines/bento_search/lib_guides_engine.rb`, `app/models/lib_guides_api.rb`,
  `app/services/archives_space_service.rb`.
- Additional wiring done for QuikPay/OCLC/SAML/cache settings:
  `app/controllers/concerns/quik_pay.rb`, `app/models/citation.rb`,
  `app/controllers/application_controller.rb`, `config/initializers/devise.rb`,
  `app/models/blacklight/primo_central/repository.rb`,
  `app/models/blacklight/primo_central/document.rb`.

Still pending:

- Infra repo QA cutover: stop injecting deprecated integration env vars in QA and run smoke tests.
- Infra repo production cleanup: remove deprecated integration env vars from Vault/Helm after QA and production validation.
- App hard cleanup: remove compatibility fallbacks and retire legacy integration `config/*.yml` once infra cutover is complete.
