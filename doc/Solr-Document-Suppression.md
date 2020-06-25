Solr Document Suppression
===

Under some conditions, for example like when an item becomes lost, a document
needs to be suppressed from search results.

The suppression of items from search results occurs via several pathways.

* At ingest time an item can be skipped.
* At ingest time an item can be marked as suppressed.
* During a user query  items that are marked suppressed can be filtered out.
* When showing availability of specific holdings for an item, suppressed holdings are hidden. 


## Harvesting (not a full ingest/reindex)
During the regular traject ingest process bound-with items are [skipped]
(because only the bound item is needed an that gets ingested separately).

Further some items are marked as [suppressed] by submitting a true value to the
`suppress_items_b` [field].  These items cannot simply be skipped because
unless we are populating an empty database then the item may already exist and
we need to update that item.


### Full re-ingest exception.
During a full re-ingest items that would normally be marked suppressed are
simply skipped as there is no need to save and index documents that are not
ever going to be presented.

These suppressed docs will be skipped if the following environment variable is
set during ingest time:

```
TRAJECT_FULL_REINDEX=yes
```

## Suppression at query time.
When we query the solr database we add an argument to [filter out results]
for which `suppress_items_b=true` 

## Suppression of individual holdings when viewing availability.
When items holdings are presented to the user, unavailable holdings are
filtered out via a [helper method]

[skipped]: https://github.com/tulibraries/tul_cob/blob/7b7f66d9f512e4591c29986595722a2ef2263e44/lib/traject/indexer_config.rb#L46
[suppressed]: https://github.com/tulibraries/tul_cob/blob/v0.6.6/lib/traject/macros/custom.rb#L518
[field]: https://github.com/tulibraries/tul_cob/blob/v0.6.6/lib/traject/indexer_config.rb#L212
[filter out results]: https://github.com/tulibraries/tul_cob/blob/v0.6.6/app/controllers/catalog_controller.rb#L213
[helper method]: https://github.com/tulibraries/tul_cob/blob/v0.6.6/app/helpers/alma_data_helper.rb#L118
