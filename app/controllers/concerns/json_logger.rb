# frozen_string_literal: true

module JsonLogger
  extend ActiveSupport::Concern

  #Convenience wrapper that passes in the logger object
  def json_request_logger(params = {})
    LogUtils.json_request_logger(logger, params)
  end

  def do_with_json_logger(log = {})
    start = { start: Time.now }
    begin
      response = yield if block_given?

      loggable = (response.loggable rescue {}) || {}

      json_request_logger(log.merge(loggable).merge(start))
    rescue Exception => e
      error = JSON.parse(e.message) rescue { error: e.message }
      json_request_logger(log.merge(error).merge(start))
      raise e
    end

    response
  end
end
