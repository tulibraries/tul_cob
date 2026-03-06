# frozen_string_literal: true

class LibkeyService
  ARTICLE_RESPONSE_FIELDS = %w[retractionNoticeUrl fullTextFile contentLocation].freeze
  JOURNAL_RESPONSE_FIELDS = %w[browzineEnabled browzineWebLink].freeze

  def initialize(config: Rails.configuration.apis.dig(:primo, :libkey), cache_config: Rails.configuration.caches)
    @config = config
    @cache_config = cache_config
  end

  def article_data_thread_for_doi(doi)
    return empty_thread if doi.blank? || !configured?

    Thread.new { article_data_for_doi(doi) }
  end

  def journal_data_thread_for_display_issns(values)
    issns = normalize_issns(values)
    return empty_thread if issns.blank? || !configured?

    Thread.new { journal_data_for_issns(issns) }
  end

  private

    attr_reader :config, :cache_config

    def article_data_for_doi(doi)
      Rails.cache.fetch(doi.to_s, expires_in: libkey_article_cache_life) do
        Primo::Search.with_retry do
          response = HTTParty.get(article_url(doi), timeout: 4) rescue {}
          response["data"]&.slice(*ARTICLE_RESPONSE_FIELDS)
        end
      end
    end

    def journal_data_for_issns(issns)
      response = HTTParty.get(journal_url(issns), timeout: 2) rescue {}
      response["data"]&.first&.slice(*JOURNAL_RESPONSE_FIELDS)
    end

    def article_url(doi)
      "#{base_url}/#{library_id}/articles/doi/#{doi}?access_token=#{access_token}"
    end

    def journal_url(issns)
      "#{base_url}/#{library_id}/search?issns=#{issns}&access_token=#{access_token}"
    end

    def normalize_issns(values)
      Array(values).map { |value| value.to_s.delete("-") }.reject(&:blank?).uniq.join(",")
    end

    def libkey_article_cache_life
      ActiveSupport::Duration.parse(cache_config[:libkey_article_cache_life])
    rescue StandardError
      12.hours
    end

    def configured?
      base_url.present? && library_id.present? && access_token.present?
    end

    def base_url
      config&.dig(:base_url)
    end

    def library_id
      config&.dig(:library_id)
    end

    def access_token
      config&.dig(:apikey)
    end

    def empty_thread
      Thread.new {}
    end
end
