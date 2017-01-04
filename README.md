# Catalog on Blacklight

A minimal Blacklight Application for exploring Temple University MARC data in preparation for migration to Alma.


## Getting started

### Install the Application
This only needs to happen the first time.

```bash
git clone git@github.com:tulibraries/tul_cob
cd tul_cob
bundle install
bundle exec rails db:migrate
```

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

Get TUL specific sample data from [TUL Wiki](https://tulibdev.atlassian.net/wiki/download/attachments/14647301/smaller_tul.dat.gz?api=v2)(Login Required)

