# frozen_string_literal: true

module ApplicationHelper
  # Gets the base_path of current_page (i.e. /articles if at /articles/foobar)
  def base_path
    File.dirname(url_for)
  end

  def login_disabled?
    Rails.configuration.features.fetch(:login_disabled, false)
  end

  def faq_link(type = :short)
    label =
      case type
      when :short
        "FAQs"
      when :long
        "Frequently Asked Questions"
      else
        type
      end

    link_to(label, "https://library.temple.edu/pages/42")
  end

  def help_link
    link_to t("ask_librarian"), Rails.configuration.ask_link, target: "_blank"
  end

  def explanation_translations(controller_name)
    case controller_name
    when "primo_central"
      t("articles.explanation_html")
    when "journals"
      t("#{controller_name}.explanation_html")
    when "catalog"
      t("blacklight.explanation_html")
    when "databases"
      t("databases.home_html")
    when "web_content"
      t("website.explanation_html")
    else
      ""
    end
  end

  def ris_path(opts = {})
    if controller_name == "bookmarks"
      bookmarks_path(opts.merge(format: "ris"))
    elsif controller_name == "primo_central"
      article_document_path(opts.merge(format: "ris"))
    else
      solr_document_path(opts.merge(format: "ris"))
    end
  end

  def render_nav_link(path, name, analytics_id = nil)
    active = is_active?(path) ? [ "active" ] : []
    button_class = ([ "nav-item nav-link header-links" ] + active).join(" ")

    link_to(name, send(path, search_params), id: analytics_id, class: button_class)
  end

  def search_params
    # current_search_session is only defined under search context:
    # Therefore it will not be available in /users/sign_in etc.
    begin
      # Sometimes current_search_session will return nil.
      current_search_session&.query_params&.except(:controller, :action) || {}
    rescue
      {}
    end
  end

  def is_active?(path)
    url_path = send(path)
    root_page = [ :everything_path ]
    request.original_fullpath.match?(/^#{url_path}/) ||
      current_page?(root_path) && root_page.include?(path)
  end

  def citation_labels(format)
    case format
    when "APA"
      format = "APA (6th)"
    when "MLA"
      format = "MLA (7th)"
    when "CHICAGO"
      format = "Chicago Author-Date (15th)"
    when "HARVARD"
      format = "Harvard (18th)"
    when "TURABIAN"
      format = "Chicago Notes & Bibliography (15th)/Turabian (6th)"
    end
  end

  def presenter_field_value(presenter, field)
    if blacklight_config.show_fields[field]
      presenter.field_value(blacklight_config.show_fields[field])
    end
  end

  def manifold_alerts
    # @manifold_alerts_thread is set in the application controller via a before_action.
    @manifold_alerts_thread&.value&.select { |a| a if a.dig("attributes", "for_header") == false }
  end

  def emergency_alert_messages
    unless manifold_alerts.nil?
      messages = []
      manifold_alerts.map { |a|
        message = a.dig("attributes", "scroll_text")

        link = a.dig("attributes", "link")

        if !link.blank?
          messages << message + " " + link_to(t("blacklight.banner_link"), link)
        else
          messages << message
        end
      }
      messages.join(" ").html_safe
    end
  end

  def format_classes_for_icons(document)
    document["format"].first.downcase.gsub(" ", "_").gsub("/", "_")
  end

  def skip_links
    if search_fields.length == 1
      link_to t("blacklight.skip_links.search_field"), "#search_field", class: "element-invisible element-focusable rounded-bottom py-2 px-3", data: { turbolinks: "false" }
    else
      link_to t("blacklight.skip_links.search_field"), "#search_field_dropdown", class: "element-invisible element-focusable rounded-bottom py-2 px-3", data: { turbolinks: "false" }
    end
  end

  def creator_links(args)
    separator = args.dig(:config, :separator)
    creator = args[:document][args[:field]] || []
    creator.delete("null")

    creator_links = creator.map do |creator_data|
      begin
        if controller_name == "primo_central"
          name = creator_data
        else
          creator_data = JSON.parse(creator_data)
          relation = creator_data["relation"]
          name = creator_data["name"]
          role = creator_data["role"]
        end
      rescue JSON::ParserError
        name, role = creator_data.split("|")
      end

      if controller_name == "primo_central"
        name_link = link_to(name, search_article_search_url + "?search_field=creator&q=#{name}") if name.present?
      else
        name_link = link_to(name, search_catalog_path + "?f[creator_facet][]=#{CGI.escape name}") if name.present?
      end

      ActiveSupport::SafeBuffer.new([ relation,
        name_link,
        role ].join(" ").strip)
    end

    if separator.present?
      creator_links.join(separator).html_safe
    else
      creator_links
    end
  end
end
