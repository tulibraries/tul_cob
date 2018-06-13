# frozen_string_literal: true

require "rails_helper"

RSpec.describe "primo_central/_button_online.html.erb", type: :view do
  it "adds the expected parameter to the iframe source link" do
    view.instance_variable_set("@document", "link" => "", "pnxId" => "")
    expect(view.render("online_button")).to match(/is_new_ui=true/)
  end
end
