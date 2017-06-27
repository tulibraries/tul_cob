require 'rsolr'

namespace :fortytu do
  namespace :solr do

    desc 'Posts fixtures to Solr'
    task :load_fixtures do
      `traject -c app/models/traject_indexer.rb spec/fixtures/marc_fixture.xml`
      `traject -c app/models/traject_indexer.rb -x commit`
    end

    desc 'Delete fixtures from Solr'
    task :empty_index do
      solr = RSolr.connect :url => Blacklight.connection_config[:url]
      solr.update data: '<delete><query>*:*</query></delete>'
      solr.update data: '<commit/>'
    end
  end
end
