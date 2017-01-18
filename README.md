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

## Early Alma API Access

_This will change after implementation of Alma authentication_

The Alma API requires an Alma ID. Set this attribute in the User object by hand

```bash
$ rails console
[1] pry(main)> User.first.update_attribute(:alma_id, "exampleID")
  User Load (1.8ms)  SELECT  "users".* FROM "users" ORDER BY "users"."id" ASC LIMIT ?  [["LIMIT", 1]]
   (0.1ms)  begin transaction
  SQL (5.7ms)  UPDATE "users" SET "alma_id" = ?, "updated_at" = ? WHERE "users"."id" = ?  [["alma_id", "exampleID"], ["updated_at", 2017-01-18 15:19:23 UTC], ["id", 2]]
   (10.8ms)  commit transaction
=> true
[2] pry(main)> exit
```
