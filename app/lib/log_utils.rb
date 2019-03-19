# frozen_string_literal: true

module LogUtils
  # Rails limits access to the request context to controllers.
  thread_mattr_accessor :request

  def self.json_request_logger(logger, params = {})
    start = params.delete(:start)
    now = Time.now
    params[:timestamp] = now
    # It's still possible for request to be nil in batch context.
    # (i.e. when this module is used outside of Rails)
    params[:referer] = request.referer if request
    params[:user_agent] = request.user_agent if request
    params[:duration] = (now - start) if start

    logger.info JSON.dump(params)
  end
end
