# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationMailer, type: :mailer do
  describe "Simple instantiation test in lieu of implementation" do
    subject { ApplicationMailer.new }
    it { is_expected.to be }
  end

  it "does not hardcode a from address" do
    expect(described_class.default_params[:from]).to be_nil
  end
end
