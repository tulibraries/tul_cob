# frozen_string_literal: true

module LibrarySearch
  class SearchBarComponent < Blacklight::SearchBarComponent
    ADVANCED_SEARCH_PARAM_KEYS = %i[qt q_1 q_2 q_3 f_1 f_2 f_3 operator op_1 op_2 clause op f_inclusive].freeze

    def initialize(url:, params:, **options)
      super(url:, params:, **options.merge(classes: options.fetch(:classes, %w[search-query-form d-flex])))

      @url = url
      @controller = params[:controller].to_s
      @advanced_search_params = params.to_h.with_indifferent_access.except(:controller, :action, :page, :commit, :utf8, :processed)
      @params = params.except(:q, :search_field, :utf8, :page, *ADVANCED_SEARCH_PARAM_KEYS)
    end

    def advanced_search_url
      case @advanced_search_url.present?
      when false
        @advanced_search_url
      else
        uri = URI.parse(@advanced_search_url)
        case uri.path
        when "/advanced"
          uri.path = advanced_search_path
        end
        query = Rack::Utils.parse_nested_query(uri.query).merge(@advanced_search_params)
        uri.query = query.to_query.presence
        uri.to_s
      end
    end

    def advanced_search_link_text
      I18n.t("blacklight.advanced_search.#{advanced_search_link_type}_link")
    end

    private

      def advanced_search_link_type
        case URI.parse(@advanced_search_url.to_s).path
        when "/journals/advanced"
          "journals"
        when "/articles/advanced"
          "articles"
        when "/databases/advanced"
          "databases"
        else
          case @controller
          when "journals"
            "journals"
          when "primo_central"
            "articles"
          when "databases"
            "databases"
          else
            case URI.parse(@url.to_s).path
            when "/journals"
              "journals"
            when "/articles"
              "articles"
            when "/databases"
              "databases"
            else
              "catalog"
            end
          end
        end
      end

      def advanced_search_path
        case advanced_search_link_type
        when "journals"
          "/journals/advanced"
        when "articles"
          "/articles/advanced"
        when "databases"
          "/databases/advanced"
        else
          "/catalog/advanced"
        end
      end
  end
end
