# frozen_string_literal: true

# Preliminary work on Alma::Electronic APIs that will eventually be moved to
# the alma_rb gem.
module Alma
  class Electronic
    class ElectronicError < ArgumentError
    end

    def self.get(params = {})
      get_api params
    end

  private
    class ElectronicAPI
      include HTTParty
      include Enumerable
      extend Forwardable

      REQUIRED_PARAMS = []
      RESOURCE = "/almaws/v1/electronic"

      attr_reader :params, :data
      def_delegators :@data, :each, :each_pair, :fetch, :values, :keys, :dig,
        :slice, :except, :to_h, :to_hash, :[], :with_indifferent_access

      def initialize(params = {})
        @params = params
        response = self.class::get(url, headers: self.class::headers, query: params)
        @data = JSON.parse(response.body) rescue {}
      end

      def url
        "#{Alma.configuration.region}#{resource}"
      end

      def resource
        @params.inject(self.class::RESOURCE) { |path, param|
          key = param.first
          value = param.last

          if key && value
            path.gsub(/:#{key}/, value)
          else
            path
          end
        }
      end

      def self.can_process?(params = {})
        type = self.to_s.split("::").last.parameterize
        self::REQUIRED_PARAMS.all? { |param| params.include? param } &&
          params[:type].blank? || params[:type] == type
      end

    private
      def self.headers
        { "Authorization": "apikey #{apikey}",
         "Accept": "application/json",
         "Content-Type": "application/json" }
      end

      def self.apikey
        Alma.configuration.apikey
      end
    end

    class Portfolio < ElectronicAPI
      REQUIRED_PARAMS = [ :collection_id, :service_id, :portfolio_id ]
      RESOURCE = "/almaws/v1/electronic/e-collections/:collection_id/e-services/:service_id/portfolios/:portfolio_id"
    end

    class Service < ElectronicAPI
      REQUIRED_PARAMS = [ :collection_id, :service_id ]
      RESOURCE = "/almaws/v1/electronic/e-collections/:collection_id/e-services/:service_id"
    end

    class Services < ElectronicAPI
      REQUIRED_PARAMS = [ :collection_id, :type ]
      RESOURCE = "/almaws/v1/electronic/e-collections/:collection_id/e-services"
    end

    class Collection < ElectronicAPI
      REQUIRED_PARAMS = [ :collection_id ]
      RESOURCE = "/almaws/v1/electronic/e-collections/:collection_id"
    end

    # Catch all Electronic API.
    class Default < ElectronicAPI
      def initialize(params = {})
        raise ElectronicError.new "No Electronic API found to process given parameters."
      end

      def self.can_process?(params = {})
        true
      end
    end

    # Order matters because parameters can repeat.
    REGISTERED_APIs = [Portfolio, Service, Services, Collection, Default]

    def self.get_api(params)
      REGISTERED_APIs
        .find { |m| m.can_process? params }
        .new(params)
    end
  end
end
