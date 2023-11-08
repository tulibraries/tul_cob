# frozen_string_literal: true

module BentoDisplayHelper
  def total_items(results)
    results.total_items[:query_total] || 0 rescue 0
  end

  def total_online(results)
    results.total_items[:online_total] || 0 rescue 0
  end

  def bento_engine_nice_name(engine_id)
    I18n.t("bento.#{engine_id}.nice_name")
  end

  def bento_icons(engine_id)
    case engine_id
    when "articles"
      content_tag(:span, "", class: "bento-icon bento-article m-3")
    when "journals"
      content_tag(:span, "", class: "bento-icon bento-journal m-3")
    when "databases"
      content_tag(:span, "", class: "bento-icon bento-database m-3")
    when "books_and_media"
      content_tag(:span, "", class: "bento-icon bento-book m-3")
    when "library_website"
      content_tag(:span, "", class: "bento-icon bento-website m-3")
    when "lib_guides"
      content_tag(:span, "", class: "bento-icon bento-guide m-3")
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
    when "blacklight", "books_and_media"
      url = search_catalog_path(q: params[:q], f: { availability_facet: ["Online"] })
      link_to "View all #{total} online items", url
    when "journals"
      url = search_journals_path(q: params[:q], f: { availability_facet: ["Online"] })
      link_to "View all #{total} online journals", url
    when "articles"
      url = url_for(
        action: :index, controller: :primo_central,
        q: params[:q], f: { availability_facet: ["Online"] }
      )
      link_to "View all #{total} online articles", url
    else
      ""
    end
  end
end
