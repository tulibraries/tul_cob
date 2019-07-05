# 1. Use separate Solr cores for the AZ database documents. 

Date: 2018-12-6

## Status

Accepted

## Context

In deciding to serve AZ Database documents from our Solr DB, we are faced with a decision: Do we share the single Solr core for our BL database or do we create a new dedicated Solr core.

### Pros:
* Having a dedicated core means that we can more easily manage the processing of either documents independent of the other.  Just because a time consuming re-indexing of the marc records is running, does not mean that a quick re-indexing of the AZ Database records cannot happen.

* We do not need to be concerned with field name clashes.

* We do not need to be concerned document cross overs happening in query searches (i.e. I expect only marc documents but some az database documents get returned too)

### Cons:
* If in the future we want to have some integrated results, it will be a little more complex to create these queries (require solr joins).

* There is a slight cost to maintaining a separate solr core.

* The architecture is slightly more complex because there are multiple cores to reason about.


## Decision

We have decided to go with multiple cores mainly because we believe that we gain a higher benefit by keeping the marc and az documents decoupled.  We want to be able to process az database documents without needing to think about the implications to our marc document processing and vise versa.

## Consequences

Both processing of solr marc and az database documents happens via traject ingest. However, the main consequence of this decision will likely be that we must keep separate jobs to handle marc ingest vs document ingest.
