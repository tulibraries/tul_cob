# frozen_string_literal: true

require "rails_helper"
require "ostruct"

RSpec.describe "catalog/_show_tools.html.erb" do
  class FakeShowToolsViewActionComponent < ViewComponent::Base
    def initialize(action:, link_classes:, **)
      @action = action
      @link_classes = link_classes
    end

    def call
      helpers.link_to("#{@action.key}-inner", "#", class: @link_classes)
    end
  end

  let(:document) { double("SolrDocument", citable?: true) }
  let(:current_user) { double("User") }
  let(:actions) do
    [
      OpenStruct.new(key: :bookmark, component: FakeShowToolsViewActionComponent),
      OpenStruct.new(key: :email, component: FakeShowToolsViewActionComponent)
    ]
  end

  before do
    assign(:document, document)
    allow(Flipflop).to receive(:citeproc_citations?).and_return(false)
    view.instance_variable_set(:@spec_actions, actions)
    view.define_singleton_method(:document_actions) { |_doc| @spec_actions }
    view.define_singleton_method(:build_error_libwizard_url) { |_doc| "/error" }
    view.instance_variable_set(:@spec_user, current_user)
    view.define_singleton_method(:current_user) { @spec_user }
    allow(view).to receive(:request).and_return(instance_double(ActionDispatch::Request, original_fullpath: "/catalog/123"))
    allow(view).to receive(:new_user_session_path).with(
      redirect_to: "/catalog/123",
      login_message: "email"
    ).and_return("/users/sign_in?login_message=email&redirect_to=%2Fcatalog%2F123")
  end

  it "does not render the cite button when citeproc is disabled" do
    render partial: "catalog/show_tools"

    expect(rendered).not_to include("citeLink")
  end

  context "when the user is not signed in" do
    let(:current_user) { nil }

    it "replaces the email action with a login-required link" do
      render partial: "catalog/show_tools"

      expect(rendered).to include("Email (log in required)")
      expect(rendered).to include("/users/sign_in?login_message=email&amp;redirect_to=%2Fcatalog%2F123")
      expect(rendered).not_to include(">email-inner<")
    end
  end
end
