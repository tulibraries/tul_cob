# frozen_string_literal: true

require "rails_helper"

RSpec.describe BookmarksController do
  describe "#blacklight_config" do
    it "uses POST requests for querying solr" do
      expect(@controller.blacklight_config.http_method).to eq :post
    end
  end

  # jquery 1.9 ajax does error callback if 200 returns empty body. so use 204 instead.
  describe "update" do
    it "has a 200 status code when creating a new one" do
      put :update, xhr: true, params: { id: "2007020969", format: :js }
      expect(response).to be_success
      expect(response.code).to eq "200"
      expect(JSON.parse(response.body)["bookmarks"]["count"]).to eq 1
    end

    it "has a 500 status code when create is not success" do
      allow(@controller).to receive_message_chain(:current_or_guest_user, :existing_bookmark_for).and_return(false)
      allow(@controller).to receive_message_chain(:current_or_guest_user, :persisted?).and_return(true)
      allow(@controller).to receive_message_chain(:current_or_guest_user, :bookmarks, :where, :exists?).and_return(false)
      allow(@controller).to receive_message_chain(:current_or_guest_user, :bookmarks, :create).and_return(false)
      put :update, xhr: true, params: { id: "iamabooboo", format: :js }
      expect(response.code).to eq "500"
    end
  end

  describe "create" do
    it "can create bookmarks via params bookmarks attribute" do
      @controller.send(:current_or_guest_user).save
      put :create, xhr: true, params: {
        id: "notused",
        bookmarks: [
          { document_id: "2007020969", document_type: "SolrDocument" },
          { document_id: "2007020970", document_type: "SolrDocument" },
          { document_id: "2007020971", document_type: "SolrDocument" },
        ],
        format: :js
      }

      expect(response).to be_success
      expect(response.code).to eq "200"
      expect(JSON.parse(response.body)["bookmarks"]["count"]).to eq 3
    end
  end

  describe "delete" do
    before do
      @controller.send(:current_or_guest_user).save
      @controller.send(:current_or_guest_user).bookmarks.create! document_id: "2007020969", document_type: "SolrDocument"
    end

    it "has a 200 status code when delete is success" do
      delete :destroy, xhr: true, params: { id: "2007020969", format: :js }
      expect(response).to be_success
      expect(response.code).to eq "200"
      expect(JSON.parse(response.body)["bookmarks"]["count"]).to eq 0
    end

    it "can handle bookmark deletion via params" do
      class FooDocument < SolrDocument; end
      @controller.send(:current_or_guest_user).bookmarks.create! document_id: "2007020970", document_type: "FooDocument"
      delete :destroy, xhr: true, params: {
        id: "notused",
        bookmarks: [
          { document_id: "2007020969", document_type: "SolrDocument" },
          { document_id: "2007020970", document_type: "FooDocument" }
        ],
        format: :js
      }
      expect(response).to be_success
      expect(response.code).to eq "200"
      expect(JSON.parse(response.body)["bookmarks"]["count"]).to eq 0
    end

    it "has a 500 status code when delete is not success" do
      bm = instance_double(Bookmark)
      allow(@controller).to receive_message_chain(:current_or_guest_user, :existing_bookmark_for).and_return(bm)
      allow(@controller).to receive_message_chain(:current_or_guest_user, :bookmarks, :find_by).and_return(instance_double(Bookmark, delete: nil, destroyed?: false))
      delete :destroy, xhr: true, params: { id: "pleasekillme", format: :js }

      expect(response.code).to eq "500"
    end
  end
end
