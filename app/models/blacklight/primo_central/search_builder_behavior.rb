module Blacklight::PrimoCentral
  module SearchBuilderBehavior
    extend ActiveSupport::Concern

    included do
      self.default_processor_chain = [
          :add_query_to_primo_central,
      ]
      end


    def add_query_to_primo_central primo_central_parameters
      if blacklight_params[:q].is_a? Hash
        q = blacklight_params[:q]
        raise "FIXME, translation of Solr search for Summon"
      elsif blacklight_params[:q]
        # Create search field with variable, pattern and :q
        primo_central_parameters[:q] = blacklight_params[:q]
      end
    end
  end
end
