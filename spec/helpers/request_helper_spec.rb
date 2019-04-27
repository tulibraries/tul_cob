# frozen_string_literal: true

require "rails_helper"

RSpec.describe RequestHelper, type: :helper do
  describe "#ez_borrow_link_with_updated_query(url)" do
    let(:url) { "https://e-zborrow.relais-host.com/user/login.html?group=patron&LS=TEMPLE&dest=discovery&PI=12345&RK=12345&rft.stitle=A+thin+bright+line+%2F&rft.pub=The+University+of+Wisconsin+Press%2C&rft.place=Madison%2C+Wisconsin+%3A&rft.isbn=0299309304&rft.btitle=A+thin+bright+line+%2F&rft.genre=book&rft.normalized_isbn=9780299309305&rft.oclcnum=946770187&rft.mms_id=991028550499703811&rft.object_type=BOOK&rft.publisher=The+University+of+Wisconsin+Press%2C&rft.au=Bledsoe%2C+Lucy+Jane%2C+author.&rft.pubdate=%5B2016%5D&rft.title=A+thin+bright+line+%2F" }

    it "has correct link to resource" do
      expect(ez_borrow_link_with_updated_query(url)).to eq("https://e-zborrow.relais-host.com/user/login.html?group=patron&LS=TEMPLE&dest=discovery&PI=12345&RK=12345&rft.title=A+thin+bright+line+%2F")
    end
  end
end
