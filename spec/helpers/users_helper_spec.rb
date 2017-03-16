require 'rails_helper'

# Specs in this file have access to a helper object that includes
# the UsersHelper. For example:
#
# describe UsersHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
RSpec.describe UsersHelper, type: :helper do
  describe "#is_renewable" do
    it 'returns true when loan.renewable value is true' do
      loan = MockLoan.new({renewable: 'true'})
      expect(is_not_renewable?(loan)).to be false
    end

    it 'returns false when loan.renewable  is "false" ' do
      loan = MockLoan.new({renewable: 'false'})
      expect(is_not_renewable?(loan)).to be true
    end

    it 'returns true loan does not have a renewable field' do
      loan = MockLoan.new({not_renewable: 'true'})
      expect(is_not_renewable?(loan)).to be false
    end

  end
end

class MockLoan
  attr_reader :renewable
  def initialize(loan)
    if loan.fetch(:renewable, nil)
      @renewable = loan[:renewable]
    end
  end

end