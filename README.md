# Catalog on Blacklight

A minimal Blacklight Application for exploring Temple University MARC data in preparation for migration to Alma.


## Getting started

### Install the Application
This only needs to happen the first time.

```bash
git clone git@github.com:tulibraries/tul_cob
cd tul_cob
bundle install
cp config/secrets.yml.example config/secrets.yml
bundle exec rails db:migrate

```

We also need to configure the application with our Alma apikey. Start by copying the example alma config file.

```bash
cp config.alma.yml.example config/alma.yml
```

Then edit it adding in the apikey for our application specified in our Ex Libris Developer Network.


### Start the Application

We need to run two commands in separate terminal windows in order to start the application.
* In the first terminal window, start solr with run
```bash
bundle exec solr_wrapper
```
* In the second terminal window, start Puma, the rails application server
```bash
bundle exec rails server
```

## Importing Data

Download the 10000 [sample Alma MARCXML data](https://raw.githubusercontent.com/tulibraries/tul_cob/master/sample_data/sample_alma_marcxml.tgz).

Untar the sample data.
```bash
tar xvf
```

Import the MARC records with `bundle exec traject -c app/models/traject_indexer.rb PATH/TO/MARC.xml`

## Running the Tests

`bundle exec rake ci`

This will spin up a test solr instance, import a few hundred records, and run the test suite.
