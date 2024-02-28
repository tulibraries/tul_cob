# frozen_string_literal: true

module RecordMailerHelper
  def record_mailer_link(document, url_gen_params)
    url = polymorphic_url(document, @url_gen_params)
    link_to(url, url)
  end
end
