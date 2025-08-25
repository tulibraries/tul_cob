# Library Search

Library Search is a [Blacklight](https://projectblacklight.org/) project at Temple University Libraries for the discovery of library resources. See https://librarysearch.temple.edu/ for our production site.

The first phase of this project (i.e. TUL "Catalog on Blacklight") focused on search for our catalog records and fulfillment integration with our ILS, Alma. It now also includes a bento style discovery layer for: Primo Central Index article records, Springshare A-Z database records,  [library website content],(https://github.com/tulibraries/manifold)., LibGuides, and an integration with contentDM to display relevant search results from our digitized collections.

We have now added the bento_search gem to provide a bento box styled discovery layer. Users will be presented with organization of content into Books & Media, Articles, Databases, 
Journals, Library Website, Research Guides. Each bento style box presents top results in each category with links to more content. Into this discovery layer, we have also implemented
an integration with contentDM to display relevant search results from our digitized collections.

The following repositories are also critical components for Solr indexing and other integrations in the Library Search: 
* Processing pipeline: https://github.com/tulibraries/cob_datapipeline
* Catalog: https://github.com/tulibraries/cob_index, https://github.com/tulibraries/tul_cob-catalog-solr 
* A-Z databases: https://github.com/tulibraries/cob_az_index, https://github.com/tulibraries/tul_cob-az-solr
* Web content: https://github.com/tulibraries/cob_web_index, https://github.com/tulibraries/tul_cob-web-solr
* Article index: https://github.com/tulibraries/primo
* Alma client: https://github.com/tulibraries/alma_rb


[![View performance data on Skylight](https://badges.skylight.io/status/UMsaUKxxdxMC.svg)](https://oss.skylight.io/app/applications/UMsaUKxxdxMC)
[![Coverage Status](https://coveralls.io/repos/github/tulibraries/tul_cob/badge.svg?branch=main)](https://coveralls.io/github/tulibraries/tul_cob?branch=main)

## Getting started


### Install the Application
This only needs to happen the first time.

```bash
git clone git@github.com:tulibraries/tul_cob
cd tul_cob
bundle install
cp config/secrets.yml.example config/secrets.yml
```

We also need to configure the application with our Alma and Primo apikey for development work on the Bento box or User account. Start by copying the example alma and bento config files.

```bash
cp config/alma.yml.example config/alma.yml
cp config/bento.yml.example config/bento.yml
```

Then edit them adding in the API keys for our application specified in our Ex Libris Developer Network.

```bash
bundle exec rails db:migrate
```

### Start the Application for Development

We need to run two commands in separate terminal windows in order to start the application.

* In the first terminal window, start solr. Note: Make sure the SOLR_URL environment variable is set properly.
There is an example in the .env file.

```bash
git clone https://github.com/tulibraries/ansible-playbook-solrcloud.git
cd ansible-playbook-solrcloud
make up-lite
```

* In the second terminal window, start the rails app

  You can also have it ingest a few thousand sample records by setting the
  `DO_INGEST` environment variable to yes. For example:
  
```bash
# Load sample data into Solr (optional, run once if not using Option 2 below)
DO_INGEST=y bundle exec rails tul_cob:solr:load_fixtures

# Start the Rails application (choose one option):

# Option 1: With auto-recompiling CSS/JS (recommended for development)
bin/dev

# Option 2: Starts Solr, loads fixtures, and runs Rails server (all-in-one command); no auto-recompiling
bundle exec rails server
```

* Create a local user, if needed, for auth related work

  ```bash
  bundle exec rails runner "User.new(email: 'email@domain.edu', password: 'password_of_choice', admin: 1).save!"
  ```

### Start the Application using Docker as an alternative

If Docker is available, we defined a Makefile with many useful commands.

* To start the dockerized app, run ```make up```
* To stop the dockerized app, run ```make down```
* To restart the app, run ```make restart```
* To enter into the app container, run ```make tty-app```
* To enter into the solr container, run ```make tty-solr```
* To run the linter, run ```make lint```
* To run the Ruby tests, run ```make test```
  * Some tests require chromium driver to be installed on system.
    * On macs, run: `brew install chromiumdriver`
* To run Javascript tests, run ```make test-js```
* To load sample data, run ```DO_INGEST=yes make up``` or ```make load-data```
* To reload solr configs, run ```make reload-configs```
* To attatch to the running app container (good for debugging) ```make attach```
* To build prod image: ```make build ASSETS_PRECOMPILE=yes PLATFORM=arm64 BUILD_IMAGE=ruby:3.1.0-alpine```
  * `ASSETS_PRECOMPILE=no` by default
  * `PLATFORM=x86_64` by default
  * `BASE_IMAGE=harbor.k8s.temple.edu/library/ruby:3.1.0-alpine` by default
* To deploy prod image: ```make deploy VERSION=x```  VERSION=latest by default
* To run security check on image: ```make secure``` depends on trivy (brew install aquasecurity/trivy/trivy)
* To run a shell with image: ```make shell```

#### Platform Considerations
If building a docker image on m1/arm64 chip set PLATFORM env to PLATFORM=arm64 so that docker pulls an arm64 image compatible with your system.


### Preparing Alma Data

For the marcxml sample data that has been generated by Alma and exported by FTP, it needs to be processed before committing it to the sample_data folder:

```bash

./bin/massage.sh sample_data/alma_bibs.xml

```

### Ingest the sample Alma data with Traject

Now you are ready to ingest:

The simplest way to ingest a marc data file into your local solr is with the `ingest` rails task. This command can take either a local path, or a url.

```bash
bundle exec cob_index ingest sample_data/alma_bibs.xml
```

If you need to ingest a file multiple times locally and not have it rejected by SOLR do to update_date you can set `SOLR_DISABLE_UPDATE_DATE_CHECK=yes`:

```bash
SOLR_DISABLE_UPDATE_DATE_CHECK=yes bundle exec cob_index ingest spec/fixtures/purchase_online_bibs.xml
```

Under the hood, that command uses [traject](https://github.com/traject/traject), with hard coded defaults. If you need to override a default to ingest your data, You can call traject directly:

```bash
bundle exec traject -s solr.url=http://somehere/solr -c lib/traject/indexer_config.rb sample_data/alma_bibs.xml
```

If using docker, then ingest using `docker-compose exec app traject -c app/models/traject_indexer.rb sample_data/alma_bibs.xml`.

### Ingesting URLs
Additionally, you can now use `bin/ingest.rb`. This is a ruby executable that
works on both files and URLs. So now, if you want to quickly ingest a marc xml
record from production, you can run something like:

```bash
bin/ingest.rb http://example.com/catalog/foo.xml
```

### Ingest AZ Database data
AZ Database fixture data is loaded automatically when you run
`bundle exec rails tul_cob:solr:load_fixtures`. If you want to ingest a single file or URL, use `bundle exec cob_az_index ingest $path_to_file_or_url`.

Note: If you make an update to cob_az_index, you will need to run `bundle update cob_az_index` locally.

### Ingest web content data
Web content fixture data is loaded automatically when you run
`bundle exec rails tul_cob:solr:load_fixtures`. If you want to ingest a single file or URL, use `bundle exec cob_web_index ingest $path_to_file_or_url`.

Note: If you make an update to cob_web_index, you will need to run `bundle update cob_web_index` locally.

#### Ingest LibGuide AZ documents
Locally you will need to add 'az-database' core to solr (handled automatically for docker/libqa/production)

Ingest AZ database documents by running

```
./bin/libguide_cache.rb
./bin/ingest-libguides.sh
```

## Running the Tests

`bundle exec rails ci` will start solr, clean out all solr records, ingest the
test records, and run your test suite.

`bundle exec rspec` assuming you already have the test records in your test solr.
