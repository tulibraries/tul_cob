# frozen_string_literal: true

require "rails_helper"

RSpec.describe FacetsHelper do
  let(:blacklight_config) { Blacklight::Configuration.new }

  before(:each) do
    FacetsHelper.module_eval do
      def blacklight_config
      end

      def my_facet_value_renderer(item)
      end
    end

    allow(helper).to receive(:blacklight_config).and_return blacklight_config
  end

  describe "#facet_display_value" do
    it "justs be the facet value for an ordinary facet" do
      allow(helper).to receive(:facet_configuration_for_field).with("simple_field").and_return(double(query: nil, date: nil, helper_method: nil, url_method: nil))
      expect(helper.facet_display_value("simple_field", "asdf")).to eq "asdf"
    end

    it "allows you to pass in a :helper_method argument to the configuration" do
      allow(helper).to receive(:facet_configuration_for_field).with("helper_field").and_return(double(query: nil, date: nil, url_method: nil, helper_method: :my_facet_value_renderer))
      allow(helper).to receive(:my_facet_value_renderer).with("qwerty").and_return("abc")
      expect(helper.facet_display_value("helper_field", "qwerty")).to eq "abc"
    end

    it "extracts the configuration label for a query facet" do
      allow(helper).to receive(:facet_configuration_for_field).with("query_facet").and_return(double(query: { "query_key" => { label: "XYZ" } }, date: nil, helper_method: nil, url_method: nil))
      expect(helper.facet_display_value("query_facet", "query_key")).to eq "XYZ"
    end

    it "localizes the label for date-type facets" do
      allow(helper).to receive(:facet_configuration_for_field).with("date_facet").and_return(double("date" => true, :query => nil, :helper_method => nil, :url_method => nil))
      expect(helper.facet_display_value("date_facet", "2012-01-01")).to eq "Sun, 01 Jan 2012 00:00:00 +0000"
    end

    it "localizes the label for date-type facets with the supplied localization options" do
      allow(helper).to receive(:facet_configuration_for_field).with("date_facet").and_return(double("date" => { format: :short }, :query => nil, :helper_method => nil, :url_method => nil))
      expect(helper.facet_display_value("date_facet", "2012-01-01")).to eq "01 Jan 00:00"
    end

    it "removes braces from faceted value label" do
      allow(helper).to receive(:facet_configuration_for_field).with("simple_field").and_return(double(query: nil, date: nil, helper_method: nil, url_method: nil))
      expect(helper.facet_display_value("simple_field", "[asdf]")).to eq "asdf"
    end
  end
end
