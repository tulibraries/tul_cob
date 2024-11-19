# frozen_string_literal: true

module QuikPay
  extend ActiveSupport::Concern

  NO_ACCESS_MESSAGE = "You do not have access to this pay online feature. If you believe this is incorrect, please call 215-204-8212."
  ERROR_MESSAGE = "There was a problem with your transaction. Please call 215-204-8212."

  included do
    before_action :authenticate_user!, only: [ :quik_pay_callback, :quik_pay ]

    rescue_from ::QuikPay::AccessDenied do |exception|
      Honeybadger.notify(exception)
      redirect_to users_account_path, flash: { "error" => ::QuikPay::NO_ACCESS_MESSAGE }
    end

    rescue_from ::QuikPay::InvalidHash, ::QuikPay::InvalidTime, ::QuikPay::InvalidBalance, ::QuikPay::InvalidTransaction do |exception|
      Honeybadger.notify(exception)
      redirect_to users_account_path, flash: { "error" => ::QuikPay::ERROR_MESSAGE }
    end

  end

  # Redirects user to the quikpay service
  def quik_pay
    raise AccessDenied.new("This user does not have access to this feature.") unless session["can_pay_online?"]

    # Fines needs to be converted to cents
    total_fines_cents = (100 * session[:total_fines].to_f).to_i

    params = { amountDue: total_fines_cents,  orderNumber: session[:alma_sso_user] }
    redirect_to quik_pay_url(params, Rails.configuration.quik_pay["secret"]), allow_other_host: true
  end

  # Callback for processing user after they are returned from quikpay service.
  def quik_pay_callback
    validate_quik_pay_hash(params.except(:controller, :action))
    validate_quik_pay_timestamp(params["timestamp"])
    validate_quik_pay_trasaction_status(params["transactionStatus"])

    log = { type: "alma_pay", user: current_user.uid, transactionStatus: params["transActionStatus"] }

    # The return value for the do_with_json_logger block should implement Loggable.
    balance  = do_with_json_logger(log) {
      Alma::User.send_payment(user_id: current_user.uid);
    }

    validate_quik_pay_balance(balance)

    redirect_to users_account_path, flash: { notice: helpers.successful_payment_message }
  end

  def quik_pay_url(params = {}, secret = "")
    # Avoid mutating the params value
    qp_params = params.dup

    qp_params.merge!(
      orderType: "Temple Library",
      timestamp: DateTime.now.strftime("%Q").to_i,
      redirectUrl: Rails.configuration.quik_pay["redirect_url"],
      redirectUrlParameters: "transactionStatus,transactionTotalAmount",
    )

    # Use fixed params and order. This order MUST NOT be ammended or feature will stop working.
    fixed_order = [ :orderNumber, :orderType, :amountDue, :redirectUrl, :redirectUrlParameters, :timestamp ]

    ordered_params = fixed_order.reduce({}) do |params, key|
      params[key] = qp_params[key]
      params
    end

    ordered_params[:hash] = quik_pay_hash(ordered_params.values, secret)

    # I'm not using .to_query because .to_query breaks the param order by sorting.
    # We need to preserve the param order for hashing to work properly.
    qurl = Rails.configuration.quik_pay["url"]
    ordered_params.reduce(qurl) do |url, param|
      key, value = param

      value = ERB::Util.url_encode(value)
      url += "&#{key}=#{value}"
    end
  end

  def quik_pay_hash(values = [], secret = "")
    Digest::MD5.hexdigest(values.join("") + secret)
  end

  private

    class InvalidHash < StandardError
    end

    class InvalidTime < StandardError
    end

    class AccessDenied < StandardError
    end

    class InvalidBalance < StandardError
    end

    class InvalidTransaction < StandardError
    end

    def validate_quik_pay_timestamp(timestamp)
      raise InvalidTime.new("A timestamp is required. This probably means this is an invalid attempt at using quikpay.") if timestamp.nil?

      time_now = DateTime.now.strftime("%Q").to_i

      raise InvalidTime.new("The transaction attempt is coming later than 5 minutes. That's fishy since it should basically be instantaneous.  We are bailing out of precaution.") if time_now - timestamp.to_i > 300000
    end

    def validate_quik_pay_hash(params)
      hash = params["hash"]

      valid_hash = quik_pay_hash(params.except("hash").values, Rails.configuration.quik_pay["secret"])

      raise InvalidHash.new("A hash value is required. This probaly means this is an invalid attempt at using quikpay.") if hash.nil?

      raise InvalidHash.new("The hash is invalid because it does not match our calculated version of it.") if hash != valid_hash
    end

    def validate_quik_pay_balance(balance)
      raise InvalidBalance.new("An error has occurred because the balance was not paid.") unless balance.paid?
    end

    def validate_quik_pay_trasaction_status(status)
      raise InvalidTransaction.new("The QuikPay transaction was not succesful.") unless status == "1"
    end
end
