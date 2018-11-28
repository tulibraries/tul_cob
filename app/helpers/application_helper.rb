# frozen_string_literal: true

module ApplicationHelper
  # value ex: "MAIN stacks"
  def render_location(value)
    params = value.to_s.split
    [ Rails.configuration.libraries[params.first],
      Rails.configuration.locations.dig(*params) ]
      .compact
      .join(" ")
  end

  def render_location_show(value)
    render_location(value[:value].first)
  end

  def alma_build_openurl(query)
    query_defaults = {
      rfr_id: "info:sid/primo.exlibrisgroup.com",
    }

    URI::HTTPS.build(
      host: alma_domain,
      path: "/view/uresolver/#{alma_institution_code}/openurl",
      query: query_defaults.merge(query).to_query).to_s
  end

  def render_alma_eresource_link(portfolio_pid, db_name)
    link_to(db_name, alma_electronic_resource_direct_link(portfolio_pid), title: "Target opens in new window", target: "_blank")
  end

  def alma_electronic_resource_direct_link(portfolio_pid)
    query = {
        "u.ignore_date_coverage": "true",
        "Force_direct": true,
        portfolio_pid: portfolio_pid
    }
    alma_build_openurl(query)
  end

  def aeon_request_url(item)
    place_of_publication = item.item.dig("bib_data", "place_of_publication") || ""
    publisher_const = item.item.dig("bib_data", "publisher_const") || ""
    date_of_publication = item.item.dig("bib_data", "date_of_publication") || ""
    form_fields = {
         ItemTitle: (item.item.dig("bib_data", "title") || ""),
         ItemPlace: place_of_publication + publisher_const + date_of_publication,
         ReferenceNumber: (item.item.dig("bib_data", "mms_id") || ""),
         CallNumber: item.call_number || "",
         ItemAuthor: (item.item.dig("bib_data", "author") || "")
     }

    openurl_field_values = form_fields.map { |k, v|
      [k, v.to_s.delete('[]""')] }.to_h

    openurl_field_values["Action"] = 10
    openurl_field_values["Form"] = 30


    URI::HTTPS.build(
      host:  "temple.aeon.atlas-sys.com",
      path: "/Logon/",
      query: openurl_field_values.to_query).to_s
  end

  def aeon_request_button(items)
    if items.any? { |item| item.library.include?("SCRC") && item.location.include?("rarestacks") }
      button_to("Request to View in Reading Room", aeon_request_url(items.first), class: "aeon-request-btn btn btn-sm btn-primary")
    end
  end

  def total_items(results)
    results.total_items[:query_total] || 0 rescue 0
  end

  def total_online(results)
    results.total_items[:online_total] || 0 rescue 0
  end

  def bento_single_link(field)
    electronic_resource = field.first.split("|")
    portfolio_pid = electronic_resource.first
    alma_electronic_resource_direct_link(portfolio_pid)
  end

  def bento_engine_nice_name(engine_id)
    I18n.t("bento.#{engine_id}.nice_name")
  end

  def bento_icons(engine_id)
    case engine_id
    when "books"
      content_tag(:span, "", class: "bento-icon bento-book")
    when "articles"
      content_tag(:span, "", class: "bento-icon bento-article")
    when "journals"
      content_tag(:span, "", class: "bento-icon bento-journal")
    when "more"
      content_tag(:span, "", class: "bento-icon bento-more")
    end
  end

  def bento_link_to_full_results(results)
    total = number_with_delimiter(total_items results)
    BentoSearch.get_engine(results.engine_id).view_link(total, self)
  end

  # TODO: move to decorator or engine class.
  def bento_link_to_online_results(results)
    total = number_with_delimiter(total_online results)
    case results.engine_id
    when "blacklight"
      url = search_catalog_path(q: params[:q], f: { availability_facet: ["Online"] })
      link_to "View all #{total} online items", url, class: "full-results"
    when "journals"
      url = search_catalog_path(q: params[:q], f: {
        format: ["Journal/Periodical"],
        availability_facet: ["Online"]
      })
      link_to "View all #{total} online journals", url, class: "full-results"
    when "books"
      url = search_catalog_path(q: params[:q], f: {
        format: ["Book"],
        availability_facet: ["Online"]
      })
      link_to "View all #{total} ebooks", url, class: "full-results"
    when "more", "resource_types"
      ""
    when "articles"
      url = url_for(
        action: :index, controller: :primo_central,
        q: params[:q], f: { availability_facet: ["Online"] }
      )
      link_to "View all #{total} online articles", url, class: "full-results"
    else
      ""
    end
  end

  # Gets the base_path of current_page (i.e. /articles if at /articles/foobar)
  def base_path
    File.dirname(url_for)
  end

  # Render the index field (link)
  def index_field_url_link(arg)
    url = arg[:value].first
    link_to "direct link", url, remote: true
  end

  def login_disabled?
    Rails.configuration.features.fetch(:login_disabled, false)
  end

  def render_saved_searches?
    false
  end
  def render_search_history?
    false
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

    link_to(label, "https://library.temple.edu/library-search-faq")
  end

  def former_search_link
    link_to("former Library Search", "https://temple-primo.hosted.exlibrisgroup.com/primo-explore/search?vid=TULI&lang=en_US&sortby=rank")
  end

  def help_link
    link_to t("ask_librarian"), Rails.configuration.ask_link, target: "_blank"
  end

  def explanation_translations(controller_name)
    case controller_name
    when "books"
      t("#{controller_name}.explanation_html", href: link_to(t("books.explanation_href"), t("books.explanation_link"), target: "_blank"))
    when "primo_central"
      t("articles.explanation_html")
    when "journals"
      t("#{controller_name}.explanation_html")
    when "catalog"
      t("blacklight.explanation_html")
    else
      ""
    end
  end

  def ris_path(opts = {})
    if controller_name == "bookmarks"
      bookmarks_path(opts.merge(format: "ris"))
    elsif controller_name == "primo_central"
      primo_central_document_path(opts.merge(format: "ris"))
    else
      solr_document_path(opts.merge(format: "ris"))
    end
  end

  def render_nav_link(path, name, analytics_id = "")
    active = is_active?(path) ? [ "active" ] : []
    button_class = ([ "nav-btn header-links" ] + active).join(" ")
    link_class = ([ "nav-link" ] + active).join(" ")

    content_tag :li, class: button_class do
      link_to(name, send(path, search_params), class: link_class, id: analytics_id)
    end
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
end
