# frozen_string_literal: true

module QuikPay
  extend ActiveSupport::Concern

  def quik_pay_hash(values = [], secret = "")
    Digest::SHA256.hexdigest(values.join("") + secret)
  end

  def quik_pay_url(params = {}, secret = "")
    #TODO
    # * get actual quickpay URL path
    # * get actual orderType cc for credit card, but is that exactly it.

    qp_params = params.dup

    qp_params.merge!(
      orderType: "cc",
      timeStamp: Time.now.getutc.to_i,
      redirectUrl: "https://librarysearch.temple.edu/users/pay",
      redirectUrlParameters: "transactionStatus,transactionTotalAmount",
    )

    qp_params[:hash] = quik_pay_hash(qp_params.values, secret)

    # I'm not using .to_query because .to_query breaks the param order by sorting.
    # We need to preserve the param order for hashing to work properly.
    qp_params.reduce("https://quikpay.com/temple2?") do |url, param|
      key, value = param
      url += "&#{key}=#{value}"
    end
  end
end
