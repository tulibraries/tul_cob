# frozen_string_literal: true

module QuikPay
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!, only: [ :quik_pay_callback, :quik_pay ]
  end

  # Redirects user to the quikpay service
  def quik_pay
    raise AccessDenied.new("This user does not have access to this feature.") unless session["can_pay_online?"]

    params = { amountDue: session[:total_fines] }
    redirect_to quik_pay_url(params, Rails.configuration.quik_pay["secret"])
  end

  # Callback for processing user after they are returned from quikpay service.
  def quik_pay_callback
    validate_quik_pay_hash(params.except(:controller, :action))
    validate_quik_pay_timestamp(params["timeStamp"])

    log = { type: "alma_pay", user: current_user.id, transActionStatus: params["transActionStatus"] }

    type, message = do_with_json_logger(log) {
      case params["transActionStatus"]
      when "1"
        balance = Alma::User.send_payment(user_id: current_user.uid);
        if balance.paid?
          type = :info
        else
          type = :error
        end

        message = balance.payment_message
      when "2"
        type =  :error
        message = "Rejected credit card payment/refund (declined)"
      when "3"
        type = :error
        message = "Error credit card payment/refund (error)"
      when "4"
        type = :error
        message = "Unknown credit card payment/refund (unknown)"
      end

      [type, message]
    }

    redirect_to users_account_path, flash: { type => message }
  end

  def quik_pay_url(params = {}, secret = "")
    # Avoid mutating the params value
    qp_params = params.dup

    qp_params.merge!(
      orderType: "Temple Library",
      timeStamp: Time.now.getutc.to_i,
      redirectUrl: Rails.configuration.quik_pay["redirect_url"],
      redirectUrlParameters: "transactionStatus,transactionTotalAmount",
    )

    qp_params[:hash] = quik_pay_hash(qp_params.values, secret)

    # I'm not using .to_query because .to_query breaks the param order by sorting.
    # We need to preserve the param order for hashing to work properly.
    qp_params.reduce("https://uatquikpay.com/temple2/temple/library/guest_payer.do?") do |url, param|
      key, value = param

      value = ERB::Util.url_encode(value)
      url += "&#{key}=#{value}"
    end
  end

  def quik_pay_hash(values = [], secret = "")
    Digest::SHA256.hexdigest(values.join("") + secret)
  end

  private

    class InvalidHash < StandardError
    end

    class InvalidTime < StandardError
    end

    class AccessDenied < StandardError
    end

    def validate_quik_pay_timestamp(timeStamp)
      raise InvalidTime.new("A timeStamp is required. This probably means this is an invalid attempt at using quikpay.") if timeStamp.nil?

      time_now = Time.now.getutc.to_i

      raise InvalidTime.new("The transaction attempt is coming later than 5 minutes. That's fishy since it should basically be instantaneous.  We are bailing out of precaution.") if time_now - timeStamp.to_i > 300
    end

    def validate_quik_pay_hash(params)
      hash = params["hash"]
      valid_hash = quik_pay_hash(params.except("hash").values, Rails.configuration.quik_pay["secret"])

      raise InvalidHash.new("A hash value is required. This probaly means this is an invalid attempt at using quikpay.") if hash.nil?

      raise InvalidHash.new("The hash is invalid because it does not match our calculated version of it.") if hash != valid_hash
    end
end
