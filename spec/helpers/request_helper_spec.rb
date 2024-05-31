# frozen_string_literal: true

require "rails_helper"

RSpec.describe RequestHelper, type: :helper do
  describe "#ez_borrow_link_title(url)" do
    let(:url) { "https://ezborrow.reshare.indexdata.com/?group=patron&LS=TEMPLE&dest=discovery&PI=12345&RK=12345&rft.stitle=A+thin+bright+line+%2F&rft.pub=The+University+of+Wisconsin+Press%2C&rft.place=Madison%2C+Wisconsin+%3A&rft.isbn=0299309304&rft.btitle=A+thin+bright+line+%2F&rft.genre=book&rft.normalized_isbn=9780299309305&rft.oclcnum=946770187&rft.mms_id=991028550499703811&rft.object_type=BOOK&rft.publisher=The+University+of+Wisconsin+Press%2C&rft.au=Bledsoe%2C+Lucy+Jane%2C+author.&rft.pubdate=%5B2016%5D&rft.title=A+thin+bright+line+%2F" }

    it "has correct link to resource" do
      expect(ez_borrow_link_title(url)).to eq("https://ezborrow.reshare.indexdata.com/Search/Results?lookfor=A+thin+bright+line+%2F&type=Title")
    end
  end

  describe "#request_redirect_url" do

    it "generates expected url" do
      helper.extend(UsersHelper)
      expected_url = "/users/sign_in?redirect_to=http%3A%2F%2Ftest.host%2Falmaws%2Frequest%2Ffoo"
      expect(helper.request_redirect_url("foo")).to eq(expected_url)
    end
  end

  describe "#modal_exit_button_name" do

    context "make_modal_link is false" do
      it "does not render the name as a link" do
        expect(helper.modal_exit_button_name(false)).to eq("&times;")
      end
    end

    context "make_modal_link is true" do
      it "renders the name as a link" do
        expect(helper.modal_exit_button_name(true)).to eq("<a class=\"nav-item nav-link header-links\" href=\"/catalog\">&times;</a>")
      end
    end
  end

  describe "#aeon_request_allowed(document)" do
    context "item is at SCRC" do
      let(:document) { { "items_json_display" =>
        [{ "item_pid" => "23237957740003811",
        "item_policy" => "5",
        "permanent_library" => "SCRC",
        "permanent_location" => "rarestacks",
        "current_library" => "SCRC",
        "current_location" => "rarestacks",
        "call_number" => "DVD 13 A165",
        "holding_id" => "22237957750003811" }]
          }
        }

      it "returns true" do
        expect(helper.aeon_request_allowed(document)).to be true
      end
    end

    context "item is at SCRC" do
      let(:document) { { "items_json_display" =>
        [{ "item_pid" => "23237957740003811",
        "item_policy" => "5",
        "permanent_library" => "MAIN",
        "permanent_location" => "stacks",
        "current_library" => "MAIN",
        "current_location" => "rarestacks",
        "call_number" => "DVD 13 A165",
        "holding_id" => "22237957750003811" }]
          }
        }

      it "returns true" do
        expect(helper.aeon_request_allowed(document)).to be false
      end
    end
  end

  describe "#aeon_request_button(document)" do
    context "item is at SCRC" do
      let(:document) { { "items_json_display" =>
        [{ "item_pid" => "23237957740003811",
        "item_policy" => "5",
        "permanent_library" => "SCRC",
        "permanent_location" => "rarestacks",
        "current_library" => "SCRC",
        "current_location" => "rarestacks",
        "call_number" => "DVD 13 A165",
        "holding_id" => "22237957750003811" }]
          }
        }

      it "display the aeon request button" do
        expect(helper.aeon_request_button(document)).to have_button("Go to SCRC Researcher Account")
      end
    end

    context "item is NOT at SCRC" do
      let(:document) { { "items_json_display" =>
        [{ "item_pid" => "23237957740003811",
        "item_policy" => "5",
        "permanent_library" => "MAIN",
        "permanent_location" => "stacks",
        "current_library" => "Main",
        "current_location" => "stacks",
        "call_number" => "DVD 13 A165",
        "holding_id" => "22237957750003811" }]
          }
        }

      it "display the aeon request button" do
        expect(helper.aeon_request_button(document)).to_not have_button("Go to SCRC Researcher Account")
      end
    end
  end
end
