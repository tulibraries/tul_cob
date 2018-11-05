# frozen_string_literal: true

class PurchaseOrderMailer < RecordMailer
  def purchase_order(document, details, url_gen_params)
    title = begin
              document.to_semantic_values[:title]
            rescue
              I18n.t("blacklight.email.text.default_title")
            end
    subject = "Purchase Order: " + title.first

    @document       = document
    @message        = details[:message]
    @url_gen_params = url_gen_params
    @from_email     = details[:from]

    mail(to: "orders@temple.edu",  subject: subject)
  end
end
