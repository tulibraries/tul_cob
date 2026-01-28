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

  describe "searching databases az", order: :defined do
    render_views
    @all_ids, @title_ids, @subject_ids = nil

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
      @all_ids = all_ids
    end

    it "collects ids for title search" do
      expect(title_ids.count).not_to eq(0)
      @title_ids = title_ids
    end

    it "collects ids for subject search" do
      expect(subject_ids.count).not_to eq(0)
      @subject_ids = subject_ids
    end

    it "has different search results for title vs subject vs all."  do
      expect(@all_ids).not_to match_array(@title_ids)
      expect(@all_ids).not_to match_array(@subject_ids)
      expect(@title_ids).not_to match_array(@subject_ids)
    end
  end

  describe "before_action override_solr_path " do

    context ":index action and quoted single term search (double quoted)" do
      it "does not override the blacklight_config solr_path" do
        get :index, params: { q: '"art"' }
        expect(assigns(:blacklight_config).solr_path).to eq("search")
      end
    end

    context ":index action and quoted single term search (single quoted)" do
      it "does not override the blacklight_config solr_path" do
        get :index, params: { q: "'art'" }
        expect(assigns(:blacklight_config)&.solr_path).to eq("search")
      end
    end

    context ":index action and non-quoted single term search" do
      it "does not override the blacklight_config solr_path" do
        get :index, params: { q: "art" }
        expect(assigns(:blacklight_config).solr_path).to eq("search")
      end
    end

    context ":index action and single term with apostrophe" do
      it "does not override the blacklight_config solr_path" do
        get :index, params: { q: "david's" }
        expect(assigns(:blacklight_config).solr_path).to eq("search")
      end
    end

    context ":index action and quoted multiple term search (single quoted)" do
      it "does not override the blacklight_config solr_path" do
        get :index, params: { q: "'art school'" }
        expect(assigns(:blacklight_config).solr_path).to eq("search")
      end
    end

    context ":index action and quoted multiple term search (double quoted)" do
      it "does not override the blacklight_config solr_path" do
        get :index, params: { q: "\"art school\"" }
        expect(assigns(:blacklight_config).solr_path).to eq("search")
      end
    end

    context ":index action and non-quoted multiple term search" do
      it "does not override the blacklight_config solr_path" do
        get :index, params: { q: "art school" }
        expect(assigns(:blacklight_config).solr_path).to eq("search")
      end
    end
  end

  describe "unsupported formats" do
    it "returns 400 and plain text when the format is not supported" do
      get :index, params: { format: "ris" }
      expect(response.status).to eq(400)
      expect(response.body).to eq("Unsupported format")
      expect(response.media_type).to eq("text/plain")
    end
  end
end
