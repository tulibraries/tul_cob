module Tulcob
  class BlockSuspiciousRequests
    def initialize(app)
      @app = app
    end

    def call(env)
      request = Rack::Request.new(env)

      # Block requests with suspicious parameters
      if request.params["f"] && !valid_facet_params?(request.params["f"])
        return [400, { "Content-Type" => "text/plain" }, ["Invalid request"]]
      end

      @app.call(env)
    end

    private

      def valid_facet_params?(facet_params)
        facet_params.is_a?(Hash) && facet_params.all? { |k, v| k.is_a?(String) && v.is_a?(Array) }
      end
  end
end
