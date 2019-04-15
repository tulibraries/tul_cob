# frozen_string_literal: true

require "rails_helper"

RSpec.describe SearchController, type: :controller do
  def content_dm_results
    { "results" => { "pager" => { "total" => "415" } } }
  end
end
