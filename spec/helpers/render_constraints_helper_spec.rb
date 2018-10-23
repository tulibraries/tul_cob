# frozen_string_literal: true

require "rails_helper"

RSpec.describe RenderConstraintsHelper, type: :helper do

  describe "#render_filter_element" do
    let(:config) do
      Blacklight::Configuration.new do |config|
        config.add_facet_field "type"
      end
    end
    let(:params) { ActionController::Parameters.new q: "biz" }
    let(:path) { Blacklight::SearchState.new(params, config, controller) }

    before do
      without_partial_double_verification do
        allow(helper).to receive(:blacklight_config).and_return(config)
      end
    end

    context "with unknown facet field in param" do
      subject { helper.render_filter_element("unknown_field", "journal", path) }

      it "does not render for an unknown field" do
        expect(subject).to be_empty
      end
    end
  end
end
