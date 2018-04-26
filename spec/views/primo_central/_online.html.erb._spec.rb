# frozen_string_literal: true

require "rails_helper"

RSpec.describe "primo_central/_online.html.erb", type: :view do
  it "Creates the expected tStaff View link" do
    view.instance_variable_set("@document", "link" => "")
    expect(view.render("online")).to match(/is_new_ui=true/)
  end
end
