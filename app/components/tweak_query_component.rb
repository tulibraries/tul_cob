# frozen_string_literal: true

class TweakQueryComponent < ViewComponent::Base
  def initialize(blacklight_config:, params:)
    @blacklight_config = blacklight_config
    @params = params
  end

  def render?
    Flipflop.solr_query_tweaks? && @blacklight_config.document_model == SolrDocument
  end

  def fields
    @fields ||= merged_solr_params.select { |name, _| name.match?(/(qf$|pf$)/) }
  end

  def titleize_field(name)
    "#{name}".titleize
      .gsub("Qf", "Query Fields (qf)")
      .gsub("Pf", "Phrase Fields (pf)")
  end

  private

    def merged_solr_params
      defaults = (@blacklight_config.default_solr_params || {}).transform_keys(&:to_s)
      overrides = safe_params.transform_keys(&:to_s)
      defaults.merge(overrides)
    end

    def safe_params
      return {} unless @params

      if @params.respond_to?(:permitted?) && !@params.permitted?
        @params.each_pair.with_object({}) do |(name, value), safe_params|
          safe_params[name] = value if name.to_s.match?(/(?:qf|pf)\z/)
        end
      else
        @params.to_h
      end
    end
end
