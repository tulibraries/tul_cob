# frozen_string_literal: true

module JsonLogger
  extend ActiveSupport::Concern

  #Convenience wrapper that passes in the logger object
  def json_request_logger(params = {})
    LogUtils.json_request_logger(logger, params)
  end
end
