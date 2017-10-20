require 'rails_helper'

# Specs in this file have access to a helper object that includes
# the ApplicationHelper. For example:
#
# describe ApplicationHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
RSpec.describe ApplicationHelper, type: :helper do
  describe "#electronic_resource_link_builder(args)" do
    let(:alma_domain) {"sandbox01-na.alma.exlibrisgroup.com"}
    let(:alma_institution_code) {"01TULI_INST"}

    context "only a portfolio_pid is present" do
      let(:args) {
        {
          document:
          {
            electronic_resource_display: ["12345"]
          },
          field: :electronic_resource_display
        }
      }

      it 'has correct link to resource' do
      expect(electronic_resource_link_builder(args)).to have_link(text: "Find it online", href:"https://sandbox01-na.alma.exlibrisgroup.com/view/uresolver/01TULI_INST/openurl?Force_direct=true&portfolio_pid=12345&rfr_id=info%3Asid%2Fprimo.exlibrisgroup.com&u.ignore_date_coverage=true")
      end
    end

    context "multiple subfields present" do
      let(:args) {
        {
          document:
          {
            electronic_resource_display: ["77777|Sample Name"]
          },
          field: :electronic_resource_display
        }
      }

      it 'displays database name if available' do
      expect(electronic_resource_link_builder(args)).to have_link(text: "Sample Name", href:"https://sandbox01-na.alma.exlibrisgroup.com/view/uresolver/01TULI_INST/openurl?Force_direct=true&portfolio_pid=77777&rfr_id=info%3Asid%2Fprimo.exlibrisgroup.com&u.ignore_date_coverage=true")
      end
    end
  end
end
