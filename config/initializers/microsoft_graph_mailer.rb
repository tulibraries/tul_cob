# frozen_string_literal: true

ActionMailer::Base.add_delivery_method :microsoft_graph_mailer,
  MicrosoftGraphMailer::Delivery,
  {
    user_id: "librarymessages@temple.edu",
    tenant: Rails.configuration.apis.dig(:microsoft_graph_mailer, :tenant_id),
    client_id: Rails.configuration.apis.dig(:microsoft_graph_mailer, :client_id),
    client_secret: Rails.configuration.apis.dig(:microsoft_graph_mailer, :client_secret)
  }
