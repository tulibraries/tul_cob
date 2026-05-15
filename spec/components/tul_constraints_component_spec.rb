# frozen_string_literal: true

require "rails_helper"

RSpec.describe TulConstraintsComponent, type: :component do
  class FakeConstraintPresenter
    attr_reader :constraint_classes, :parent, :label_override
    attr_accessor :constraint_label

    def initialize(initial_label = "Inner Label")
      @constraint_label = initial_label
      @constraint_classes = []
    end

    def add_constraint_class(class_name)
      @constraint_classes << class_name
    end

    def parent=(value)
      @parent = value
    end

    def constraint_label_override=(value)
      @label_override = value
    end
  end

  subject(:component) { described_class.new(search_state:) }
  let(:search_state) { instance_double(Blacklight::SearchState) }

  describe "#initialize" do
    it "uses the legacy constraint layout for query constraints" do
      config = Blacklight::Configuration.new
      real_state = Blacklight::SearchState.new({}, config)
      cmp = described_class.new(search_state: real_state)

      expect(cmp.instance_variable_get(:@query_constraint_component)).to eq(TulConstraintLayoutComponent)
    end
  end

  before do
    allow(component).to receive(:selected_values).and_return([])
  end

  describe "#decorate_presenter" do
    it "hides a library facet constraint when a matching location is selected" do
      allow(component).to receive(:selected_values).with("location_facet").and_return(["Ambler Campus Library - Stacks"])

      presenter = FakeConstraintPresenter.new
      component.send(:decorate_presenter, presenter, "library_facet", "Ambler Campus Library")

      expect(presenter.constraint_classes).to include("hidden")
    end

    it "appends the lc outer facet label to lc inner constraints" do
      allow(component).to receive(:selected_values).with("lc_outer_facet").and_return(["A - General Works"])

      presenter = FakeConstraintPresenter.new("Reference Works")
      component.send(:decorate_presenter, presenter, "lc_inner_facet", "Reference Works")

      expect(presenter.parent.field).to eq("lc_outer_facet")
      expect(presenter.label_override).to eq("A - General Works | Reference Works")
    end
  end

  describe "#facet_item_presenters" do
    let(:outer_presenter) { FakeConstraintPresenter.new }
    let(:inner_presenter) { FakeConstraintPresenter.new }
    let(:outer_config) { double("outer_config") }
    let(:inner_config) { double("inner_config") }
    let(:outer_value) { "A - General Works" }
    let(:inner_value) { "Reference Works" }

    before do
      outer_filter = double("filter", key: "lc_outer_facet", config: outer_config)
      inner_filter = double("filter", key: "lc_inner_facet", config: inner_config)
      allow(outer_filter).to receive(:each_value).and_yield(outer_value)
      allow(inner_filter).to receive(:each_value).and_yield(inner_value)
      allow(search_state).to receive(:filters).and_return([outer_filter, inner_filter])
    end

    it "skips lc_outer_facet presenters when lc_inner_facet is selected" do
      allow(component).to receive(:selected_values).and_return([])
      allow(component).to receive(:selected_values).with("lc_inner_facet").and_return(["A - General Works"])
      allow(component).to receive(:constraint_presenter_for).with(outer_config, outer_value, "lc_outer_facet").and_return(outer_presenter)
      allow(component).to receive(:constraint_presenter_for).with(inner_config, inner_value, "lc_inner_facet").and_return(inner_presenter)

      expect { |b| component.send(:facet_item_presenters).each(&b) }.to yield_successive_args(inner_presenter)
    end

    it "skips library facets when a matching location is selected" do
      allow(component).to receive(:selected_values).with("location_facet").and_return(["Ambler Campus Library - Stacks"])

      library_presenter = FakeConstraintPresenter.new
      location_presenter = FakeConstraintPresenter.new
      library_value = "Ambler Campus Library"
      location_value = "Ambler Campus Library - Stacks"
      library_filter = double("filter", key: "library_facet", config: double("library_config"))
      location_filter = double("filter", key: "location_facet", config: double("location_config"))
      allow(library_filter).to receive(:each_value).and_yield(library_value)
      allow(location_filter).to receive(:each_value).and_yield(location_value)
      allow(search_state).to receive(:filters).and_return([library_filter, location_filter])
      allow(component).to receive(:constraint_presenter_for).with(library_filter.config, library_value, "library_facet").and_return(library_presenter)
      allow(component).to receive(:constraint_presenter_for).with(location_filter.config, location_value, "location_facet").and_return(location_presenter)

      expect { |b| component.send(:facet_item_presenters).each(&b) }.to yield_successive_args(location_presenter)
    end

    it "skips the lc_facet pivot wrapper" do
      lc_facet_value = double("lc_facet_value")
      lc_filter = double("filter", key: "lc_facet", config: double("lc_config"))
      inner_filter = double("filter", key: "lc_inner_facet", config: inner_config)
      allow(lc_filter).to receive(:each_value).and_yield(lc_facet_value)
      allow(inner_filter).to receive(:each_value).and_yield(inner_value)
      allow(search_state).to receive(:filters).and_return([lc_filter, inner_filter])

      pivot_presenter = FakeConstraintPresenter.new
      allow(component).to receive(:constraint_presenter_for).with(anything, lc_facet_value, "lc_facet").and_return(pivot_presenter)
      allow(component).to receive(:constraint_presenter_for).with(anything, inner_value, "lc_inner_facet").and_return(inner_presenter)

      expect { |b| component.send(:facet_item_presenters).each(&b) }.to yield_successive_args(inner_presenter)
    end
  end
end
