# frozen_string_literal: true

require "rails_helper"
require "ostruct"

RSpec.describe "catalog/_show_tools.html.erb" do
  let(:document) { double("SolrDocument", citable?: true) }
  let(:current_user) { double("User") }

  before do
    assign(:document, document)
    allow(Flipflop).to receive(:citeproc_citations?).and_return(false)
    view.define_singleton_method(:show_doc_actions?) { true }
    view.define_singleton_method(:build_error_libwizard_url) { |_doc| "/error" }
    view.instance_variable_set(:@spec_user, current_user)
    view.define_singleton_method(:current_user) { @spec_user }
    allow(view).to receive(:request).and_return(instance_double(ActionDispatch::Request, original_fullpath: "/catalog/123"))
    allow(view).to receive(:new_user_session_path).with(
      redirect_to: "/catalog/123",
      login_message: "email"
    ).and_return("/users/sign_in?login_message=email&redirect_to=%2Fcatalog%2F123")
    view.define_singleton_method(:render_show_doc_actions) do |_doc, &block|
      [OpenStruct.new(key: :bookmark), OpenStruct.new(key: :email)].map do |config|
        inner = config.key == :bookmark ? "bookmark-inner" : "email-inner"
        block.call(config, inner).to_s
      end.join.html_safe
    end
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
