# frozen_string_literal: true

require "rails_helper"

RSpec.describe CatalogController, type: :controller do
  render_views

  controller do
    def test_basic_exception
      raise Exception.new("oof")
    end

    def test_primo_error
      raise Primo::Search::SearchError.new("Primo isn't home today")
    end
  end

  before :each do
    allow(Rails).to receive(:env) { "production".inquiry }

    routes.draw do
      get "test_basic_exception" => "catalog#test_basic_exception"
      get "test_primo_error" => "catalog#test_primo_error"
    end
  end

  it "handles its own errors gracefully" do
    get :test_basic_exception
    expect(response).to have_http_status 500
    expect(response.body).to include "We're sorry, but something went wrong"
  end

  it "handles primo's errors  gracefully" do
    get :test_primo_error
    expect(response).to have_http_status 502
    expect(response.body).to include "We're sorry, but something went wrong"
  end
end
