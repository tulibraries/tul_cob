# frozen_string_literal: true

require "rails_helper"

RSpec.describe WebContentController, type: :controller do
  it "overrides the document model" do
    expect(controller.blacklight_config.document_model).to eq(SolrWebContentDocument)
  end

  it "overrides the config connection url" do
    url = controller.blacklight_config.connection_config[:url]
    web_content_url = controller.blacklight_config.connection_config[:web_content_url]
    expect(url).to eq(web_content_url)
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
        expect(assigns(:blacklight_config)&.solr_path).to eq("search")      end
    end

    context ":index action and non-quoted single term search" do
      it "does not override the blacklight_config solr_path" do
        get :index, params: { q: '"art"' }
        get :index, params: { q: "art" }
        expect(assigns(:blacklight_config).solr_path).to eq("search")
      end
    end

    context ":index action and single term with apostrophe" do
      it "does not override the blacklight_config solr_path" do
        get :index, params: { q: '"art"' }
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
end
