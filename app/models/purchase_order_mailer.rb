# frozen_string_literal: true

class PurchaseOrderMailer < RecordMailer
  def purchase_order(document, details, url_gen_params)
    title = begin
              document.to_semantic_values[:title]
            rescue
              I18n.t("blacklight.email.text.default_title")
            end
    subject = "Purchase on Demand: " + title.first

    @document       = document
    @message        = details[:message]
    @url_gen_params = url_gen_params
    @from           = details[:from]

    mail(to: "orders@temple.edu", cc: @from[:email], subject: subject)
  end
end
