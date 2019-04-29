# frozen_string_literal: true

require "rails_helper"

RSpec.describe DatabasesController, type: :controller do
  it "overrides the document model" do
    expect(controller.blacklight_config.document_model).to eq(SolrDatabaseDocument)
  end

  it "overrides the config connection url" do
    url = controller.blacklight_config.connection_config[:url]
    az_url = controller.blacklight_config.connection_config[:az_url]
    expect(url).to eq(az_url)
  end

  describe "searching databases az", order: "defined" do
    render_views
    @@all_ids, @@title_ids, @@subject_ids = nil

    let(:all_params) { { q: "medicine", search_field: "all_fields", format: "json" } }
    let(:title_params) { { q: "medicine", search_field: "title", format: "json" } }
    let(:subject_params) { { q: "medicine", search_field: "subject", format: "json" } }

    let(:ids) { -> (results) { (results.fetch("data") || {}).map { |doc| doc.fetch("id") }.compact } }

    let(:all_ids) { ids[JSON.parse((get :index, params: all_params).body)] }
    let(:title_ids) { ids[JSON.parse((get :index, params: title_params).body)] }
    let(:subject_ids) { ids[JSON.parse((get :index, params: subject_params).body)] }

    ## Rspec only allows one request per assertion.
    it "collects ids for all search" do
      expect(all_ids.count).not_to eq(0)
      @@all_ids = all_ids
    end

    it "collects ids for title search" do
      expect(title_ids.count).not_to eq(0)
      @@title_ids = title_ids
    end

    it "collects ids for subject search" do
      expect(subject_ids.count).not_to eq(0)
      @@subject_ids = subject_ids
    end

    it "has different search results for title vs subject vs all."  do
      expect(@@all_ids).not_to match_array(@@title_ids)
      expect(@@all_ids).not_to match_array(@@subject_ids)
      expect(@@title_ids).not_to match_array(@@subject_ids)
    end

  end
end
