# frozen_string_literal: true

require "rails_helper"

RSpec.describe RequestHelper, type: :helper do
  describe "#ez_borrow_link_with_updated_query(url)" do
    let(:url) { "https://e-zborrow.relais-host.com/user/login.html?group=patron&LS=TEMPLE&dest=discovery&PI=12345&RK=12345&rft.stitle=A+thin+bright+line+%2F&rft.pub=The+University+of+Wisconsin+Press%2C&rft.place=Madison%2C+Wisconsin+%3A&rft.isbn=0299309304&rft.btitle=A+thin+bright+line+%2F&rft.genre=book&rft.normalized_isbn=9780299309305&rft.oclcnum=946770187&rft.mms_id=991028550499703811&rft.object_type=BOOK&rft.publisher=The+University+of+Wisconsin+Press%2C&rft.au=Bledsoe%2C+Lucy+Jane%2C+author.&rft.pubdate=%5B2016%5D&rft.title=A+thin+bright+line+%2F" }

    it "has correct link to resource" do
      expect(ez_borrow_link_with_updated_query(url)).to eq("https://e-zborrow.relais-host.com/user/login.html?group=patron&LS=TEMPLE&dest=discovery&PI=12345&RK=12345&rft.title=A+thin+bright+line+%2F")
    end
  end

  describe "#successful_request_message" do
    it "renders the error message text correctly" do
      expect(successful_request_message).to eq("Your request has been submitted. You will receive an email notification when an item is ready for pickup. See <a href=\"/users/account\">My Account</a> for status information about your request.")
    end

  end

  describe "#request_redirect_url" do

    it "generates expected url" do
      helper.extend(UsersHelper)
      expected_url = "/users/sign_in?redirect_to=http%3A%2F%2Ftest.host%2Falmaws%2Frequest%2Ffoo"
      expect(helper.request_redirect_url("foo")).to eq(expected_url)
    end
  end
end
