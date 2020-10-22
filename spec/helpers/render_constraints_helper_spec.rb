# frozen_string_literal: true

require "rails_helper"

RSpec.describe RenderConstraintsHelper, type: :helper do

  describe "#render_filter_element" do
    let(:config) do
      Blacklight::Configuration.new do |config|
        config.add_facet_field "pivoted", label: "Pivoted Label", pivot: ["pivoted_outer", "pivoted_inner"]
        config.add_facet_field "library_pivot_facet", pivot: [ "library_facet", "location_facet" ]
      end
    end
    let(:params) { ActionController::Parameters.new q: "biz" }
    let(:search_state) { Blacklight::SearchState.new(params, config, helper) }
    let(:values) { "foo" }
    let(:subject) { helper.render_filter_element(facet, values, search_state) }

    before do
      without_partial_double_verification do
        allow(helper).to receive(:blacklight_config).and_return(config)
        allow(helper).to receive(:search_state).and_return(search_state)
        allow(helper).to receive(:search_action_path).and_return("http://example.com")
      end
    end

    context "with unknown facet field in param" do
      let(:facet) { "unknown_field" }

      it "does not render for an unknown field" do
        expect(subject).to be_empty
      end
    end

    context "with pivoted facet field in param" do
      let(:facet) { "pivoted_outer" }

      it "does render for a pivot field" do
        expect(subject).to match(/filter-pivoted_outer/)
        expect(subject).to match(/filterName">Pivoted Label/)
      end
    end

    context "library_facet field and matching library_location" do
      let(:facet) { "library_facet" }
      let(:params) { ActionController::Parameters.new({ f: { location_facet: [ "foo - ASRS"] } }) }

      it "hides the library facet" do
        expect(subject).to match(/class=.*hidden/)
      end
    end

    context "library_facet field and no matching library_location" do
      let(:facet) { "library_facet" }
      let(:params) { ActionController::Parameters.new({ f: { location_facet: [ "bar - ASRS"] } }) }

      it "hides the library facet" do
        expect(subject).not_to match(/class=.*hidden/)
      end
    end

    context "lc_inner_facet field" do
      let(:config) do
        Blacklight::Configuration.new do |config|
          config.add_facet_field "lc_facet", label: "Library of Congress Classification", pivot: ["lc_outer_facet", "lc_inner_facet"]
        end
      end
      let(:facet) { "lc_inner_facet" }
      let(:params) { ActionController::Parameters.new({ f: { lc_outer_facet: [ "A - Bar"] } }) }

      it "uses the long label" do
        expect(subject).to match(/A - Bar \| foo/)
      end
    end
  end
end
