# frozen_string_literal: true

require "rails_helper"

RSpec.describe "books redirect", type: :request do

  it "should redirect /books/:id to /catalog/:id" do
    get "/books/foo"
    expect(response).to redirect_to("http://www.example.com/catalog/foo")
  end

  it "should redirect params as well" do
    get "/books/foo?format=json"
    expect(response).to redirect_to("http://www.example.com/catalog/foo?format=json")
  end

  it "should only substitute first occurance of books" do
    get "/books/foo?format=json&type=books"
    expect(response).to redirect_to("http://www.example.com/catalog/foo?format=json&type=books")
  end

  it "should add books filter if a books search url" do
    get "/books?q=hello"
    expect(response).to redirect_to("http://www.example.com/catalog?q=hello&f[format][]=Book")
  end

  it "should only add books filter once to URL" do
    get "/books?q=hello&f[format][]=Book"
    expect(response).to redirect_to("http://www.example.com/catalog?q=hello&f[format][]=Book")
  end

end
