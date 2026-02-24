# frozen_string_literal: true

require "rails_helper"

RSpec.describe "production credentials configuration" do
  around do |example|
    original = ENV["APP_DEPLOY_ENV"]
    example.run
    if original.nil?
      ENV.delete("APP_DEPLOY_ENV")
    else
      ENV["APP_DEPLOY_ENV"] = original
    end
  end

  def load_production_config
    load Rails.root.join("config/environments/production.rb")
  end

  it "uses qa credentials paths when APP_DEPLOY_ENV=qa" do
    ENV["APP_DEPLOY_ENV"] = "qa"

    load_production_config

    expect(Rails.application.config.credentials.content_path).to eq(Rails.root.join("config/credentials/qa.yml.enc"))
    expect(Rails.application.config.credentials.key_path).to eq(Rails.root.join("config/credentials/qa.key"))
  end

  it "uses prod credentials paths when APP_DEPLOY_ENV=prod" do
    ENV["APP_DEPLOY_ENV"] = "prod"

    load_production_config

    expect(Rails.application.config.credentials.content_path).to eq(Rails.root.join("config/credentials/prod.yml.enc"))
    expect(Rails.application.config.credentials.key_path).to eq(Rails.root.join("config/credentials/prod.key"))
  end

  it "defaults to prod credentials paths when APP_DEPLOY_ENV is missing" do
    ENV.delete("APP_DEPLOY_ENV")

    load_production_config

    expect(Rails.application.config.credentials.content_path).to eq(Rails.root.join("config/credentials/prod.yml.enc"))
    expect(Rails.application.config.credentials.key_path).to eq(Rails.root.join("config/credentials/prod.key"))
  end
end
