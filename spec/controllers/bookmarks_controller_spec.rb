# frozen_string_literal: true

require "rails_helper"

RSpec.describe BookmarksController do
  describe "index" do
    it "does not get cached" do
      get :index

      expect(response.headers["Cache-Control"]).to eq("no-cache, no-store")
      expect(response.headers["Pragma"]).to eq("no-cache")
      expect(response.headers["Expires"]).to eq("Fri, 01 Jan 1990 00:00:00 GMT")
    end
  end

  describe "export_articles" do
    it "exports urls" do
      @controller.send(:current_or_guest_user).bookmarks.create! document_id: "foo", document_type: "PrimoCentralDocument"
      @controller.send(:current_or_guest_user).bookmarks.create! document_id: "bar", document_type: "PrimoCentralDocument"

      get :export_articles
      # We successfully export test file
      expect(response).to be_successful
      expect(response.content_type).to eq("text/plain")

      description = response["Content-Disposition"]
      expect(description).to eq("attachment; filename=\"article_bookmark_urls.txt\"")

      # We export list of URLs
      urls = <<~EOT
        https://librarysearch.temple.edu/articles/foo
        https://librarysearch.temple.edu/articles/bar
      EOT
      expect(response.body).to eq(urls.strip)

      # We keep track of exports
      title_update = @controller.send(:current_or_guest_user).bookmarks.first.title
      expect(title_update).to eq("exported")
    end
  end

end
