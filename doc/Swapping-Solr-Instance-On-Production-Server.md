# Progression of Solr Collection Our Across Multiple Environments

Which solr collection is being used per environment is managed entirely by the `CATALOG_COLLECTION` environment variable set in the [.env](../.env) file.

To progress a `CATALOG_COLLECTION` update across our various environments we must first merge a PR with the `CATALOG_COLLECTION` updated (this would deploy the change to our `qa` environment).

And to deploy the same change to our stage environment we would tag a release with the same change.

And finally to make that change on production we would deploy the tagged release to production.

(Note that for local development the collection that is used is not managed by this .env variable, instead SOLR_URL is set in the[docker-compose.yml](../docker-compose.yml) file)
