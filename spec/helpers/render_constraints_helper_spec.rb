# frozen_string_literal: true

require "rails_helper"

RSpec.describe RenderConstraintsHelper, type: :helper do

  describe "#render_filter_element" do
    let(:config) do
      Blacklight::Configuration.new do |config|
        config.add_facet_field "type"
        config.add_facet_field "pivoted", label: "Pivoted Label", pivot: ["pivoted_outer", "pivoted_inner"]
      end
    end
    let(:params) { ActionController::Parameters.new q: "biz" }
    let(:path) { Blacklight::SearchState.new(params, config, controller) }

    before do
      without_partial_double_verification do
        allow(helper).to receive(:blacklight_config).and_return(config)
        allow(helper).to receive(:search_state).and_return(Blacklight::SearchState.new({}, config, helper))
        allow(helper).to receive(:search_action_path).and_return("http://example.com")
      end
    end

    context "with unknown facet field in param" do
      subject { helper.render_filter_element("unknown_field", "journal", path) }

      it "does not render for an unknown field" do
        expect(subject).to be_empty
      end
    end

    context "with pivoted facet field in param" do
      subject { helper.render_filter_element("pivoted_outer", "foo", path) }

      it "does render for a pivot field" do
        expect(subject).to match(/filter-pivoted_outer/)
        expect(subject).to match(/filterName">Pivoted Label/)
      end
    end
  end
end
