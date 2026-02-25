# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Microsoft Graph mailer initializer" do
  it "registers delivery using IntegrationConfig values" do
    allow(IntegrationConfig).to receive(:microsoft_graph_mailer).with(:tenant_id).and_return("tenant-id")
    allow(IntegrationConfig).to receive(:microsoft_graph_mailer).with(:client_id).and_return("client-id")
    allow(IntegrationConfig).to receive(:microsoft_graph_mailer).with(:client_secret).and_return("client-secret")

    expect(ActionMailer::Base).to receive(:add_delivery_method).with(
      :microsoft_graph_mailer,
      MicrosoftGraphMailer::Delivery,
      {
        user_id: "librarymessages@temple.edu",
        tenant: "tenant-id",
        client_id: "client-id",
        client_secret: "client-secret"
      }
    )

    load Rails.root.join("config/initializers/microsoft_graph_mailer.rb")
  end
end
