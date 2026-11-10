# Request parameter handling inventory

This document is the pre-change inventory for removing the application-wide
`ActionController::Parameters.permit_all_parameters = true` setting. It records
which controllers and integrations consume request parameters, the parameter
shapes they require, and the request coverage needed before the global setting is
changed.

This ticket is documentation and test-planning work only. It does not change
production parameter handling. The implementation ticket must use this inventory
to add controller-specific allowlists and preserve the valid request shapes below.

## Current baseline

- `ApplicationController` enables global parameter permission for the whole Rails
  process.
- Most application controllers currently read `params` directly and do not define
  an application-specific permitter.
- `QuikPay` validates callback fields and their hash, but does not use Rails strong
  parameters.
- `BookmarksController` calls Blacklight's `permit_bookmarks`; the implementation
  and accepted nested shapes must be confirmed against the installed Blacklight
  version before changing the global setting.
- `CatalogTrackingResilience`, `FacetParamsDedupe`, and Blacklight search helpers
  mutate or forward search parameters and need to be included in the search
  allowlist design.

## Workflow inventory

| Workflow | Controller(s) | Parameters consumed | Existing protection | Required implementation/test work |
| --- | --- | --- | --- | --- |
| Catalog search | `CatalogController` and catalog subclasses (`DatabasesController`, `JournalsController`, `PrimoCentralController`, `SearchController`, `WebContentController`) | Blacklight search state: `q`, `search_field`, `f`, `sort`, `page`, `per_page`, `facet.field`, range values, advanced-search rows, and Solr field parameters; `SearchController` additionally uses `field` | No application-specific allowlist; Blacklight receives the request params, and `CatalogTrackingResilience` stores raw search params in the session | Define a shared search-state boundary using Blacklight's supported fields. Preserve facet pagination/search, ranges, advanced-search rows, nested facets, Bento `field`, and bookmark owner context where applicable. Add request coverage for ordinary, facet, advanced, and subclass searches |
| Catalog document actions | `CatalogController` | `id`, `id_list`, `to`, `message`, `title`, and `location`, depending on availability, citation, email, and purchase-order actions | No application-specific allowlist | Add action-specific scalar/array permits. Ensure citation and inherited bookmark email actions can retrieve all intended IDs and retain message text. Add request coverage |
| Related-title lists | `QueryListController` | Search state plus `footer_field` and the current-record exclusion identifier supplied by `QueryListComponent` | No application-specific allowlist | Extend the search-state boundary with `footer_field` and `filter_id`. Add a request assertion that the exclusion reaches the Solr query |
| Bookmarks | `BookmarksController` | Search state, bookmark-owner/token context, scalar or array `id`, and nested `bookmarks[document_id]`/`bookmarks[document_type]` | Calls Blacklight's `permit_bookmarks`; global permission currently makes all nested values permitted | Confirm Blacklight's accepted shapes, add an explicit bounded application boundary where needed, and cover create, destroy, index, export, email, and multiple-record requests |
| Account and loan renewal | `UsersController` | `loan_id` for one loan and array-valued `loan_ids` for selected renewal | No application-specific allowlist | Permit the scalar/array shapes and bound the number of IDs. Add request coverage for one-loan and selected-loan renewal |
| Authentication and redirects | `SessionsController`, `Sessions::SocialLogin`, `Users::OmniauthCallbacksController`, and `ApplicationController` | Login credentials, `jwt`, `redirect_to`, `login_message`, OmniAuth/SAML `target`, and sign-out `type` | Devise and OmniAuth provide part of the workflow; application code reads these values directly | Add explicit permits without changing redirect behavior. Preserve safe redirect handling and social-login JWT fields. Add request coverage for login redirects, social login, SAML target handling, and SSO sign-out |
| Alma request workflows | `AlmawsController` | `mms_id`, `doc_id`, `redirect_to`, pickup locations, request levels, material type, hold/ASRS/booking/digitization descriptions and comments, booking dates, chapter metadata, page ranges, and `available_asrs_items` fields | No application-specific allowlist; values are passed to `RequestData`, Alma request objects, and confirmation handling | Define action-specific permits, nested material-type handling, and bounds for available ASRS items. Add request coverage for item display, options, hold, ASRS, booking, and digitization requests |
| LibGuides search | `LibGuidesController` | `q` and response `format` | No application-specific allowlist | Permit the query and format, and verify unrelated parameters do not reach `LibGuidesApi` |
| QuikPay callback | `UsersController` through `QuikPay` | `timestamp`, `transactionStatus`, `transactionTotalAmount`, `orderNumber`, and `hash` | Manual hash, timestamp, status, and balance validation; no Rails permit call | Preserve the exact signed-field set. Add a narrow permit/validation boundary and retain rejection of unexpected callback keys. Keep callback request coverage |
| Exports | Blacklight export actions in `CatalogController`, `BookmarksController`, and catalog subclasses | Route `id`, collection/search state, format, and bookmark-owner context | Blacklight export behavior currently relies on globally permitted params | Identify each export format's required fields, add the shared document/search boundary, and add request coverage for CSV/RIS/other enabled formats |
| Search history | `SearchHistoryController` | Blacklight-managed search-history inputs | Behavior comes from `Blacklight::SearchHistory`; no application-specific boundary | Audit the installed Blacklight implementation and add an adapter or permitter if it reads request parameters directly. Add request coverage before changing the global setting |
| Errors and static/configuration controllers | `ErrorsController`, `DatabasesController`, `JournalsController`, and `WebContentController` | Error actions use route/format context; the catalog-derived controllers inherit catalog search parameters | No additional application-specific request handling | Confirm inherited catalog coverage; no new payload should be introduced by these controllers |

## Existing explicit strong-parameter methods

There are no application-defined `params.permit(...)` calls in the baseline
controllers. The following are related protections that must be accounted for:

- `BookmarksController` calls Blacklight's `permit_bookmarks` for nested bookmark
  data, but the implementation is supplied by the dependency.
- `QuikPay` manually validates signed callback fields and rejects invalid hashes,
  timestamps, transaction status, and balances.
- `CatalogTrackingResilience` and `FacetParamsDedupe` currently operate on raw
  search parameters and must be moved behind the search boundary in the
  implementation ticket.
- `Users::OmniauthCallbacksController` reads `request.env["omniauth.params"]`
  directly for the SAML redirect target and needs an explicit boundary.

## Service and integration inventory

No class under `app/services` directly accepts `ActionController::Parameters`.
The controller boundaries must nevertheless protect the following integration
inputs:

- `AlmawsController` passes request-derived values to `RequestData`, Alma request
  objects, and request confirmation handling.
- `CatalogController` passes request-derived IDs and message fields to search and
  mailer workflows.
- `SearchController` passes `q` and `field` into the concurrent Bento search.
- `LibGuidesController` passes `q` to `LibGuidesApi`.
- `QuikPay` passes callback-derived identity and transaction data to payment
  processing after validation.

## Existing coverage and implementation-ticket checklist

The implementation ticket should preserve or add request-level coverage for:

- ordinary catalog search, facet pagination/search, advanced-search boundaries,
  and related-title exclusion;
- bookmark creation, deletion, tokenized ownership, collection/export retrieval,
  and multiple-record email;
- one-loan and selected-loan account renewal;
- login/social-login/SAML redirects and SSO sign-out;
- Alma hold, ASRS, booking, and digitization submissions;
- LibGuides search and QuikPay callback validation; and
- each enabled document export format.

The controller and workflow list above is the scope for the implementation ticket.
No production behavior should be changed by this inventory ticket itself.

