# frozen_string_literal: true

ActionMailer::Base.add_delivery_method :microsoft_graph_mailer,
  MicrosoftGraphMailer::Delivery,
  {
    user_id: "librarymessages@temple.edu",
    tenant: IntegrationConfig.microsoft_graph_mailer(:tenant_id),
    client_id: IntegrationConfig.microsoft_graph_mailer(:client_id),
    client_secret: IntegrationConfig.microsoft_graph_mailer(:client_secret)
  }
