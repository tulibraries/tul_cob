# frozen_string_literal: true

module QuikPay
  extend ActiveSupport::Concern

  def quik_pay_hash(values = [], secret = "")
    Digest::SHA256.hexdigest(values.join("") + secret)
  end
end
