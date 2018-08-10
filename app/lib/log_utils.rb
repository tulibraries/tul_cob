# frozen_string_literal: true

module LogUtils
  def self.json_request_logger(logger, params = {})
    start = params.delete(:start)
    now = Time.now
    params[:timestamp] = now

    params[:duration] = (now - start) if start
    logger.info JSON.dump(params)
  end
end
