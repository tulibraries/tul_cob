# frozen_string_literal: true

module SearchHelper
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

  ##
  # Links More bento block facet back to catalog or content DM link.
  # @param [Blacklight::Solr::Response::Facets::FacetField] facet_field
  # @param [String] item
  # @return [String]
  def path_for_books_and_media_facet(facet_field, item)
    if item.value == "digital_collections"
      if params[:q].blank?
        "https://digital.library.temple.edu/digital/search"
      else
        query = "#{params[:q]}".gsub("/", " ")
        "https://digital.library.temple.edu/digital/search/searchterm/#{query}/order/nosort"
      end
    else
      search_catalog_url(search_state.add_facet_params_and_redirect(facet_field, item))
    end
  end

  def renderable_results(results = @results, options = {})
    results.select { |engine_id, result| render_search?(result, options) }
  end

  def render_search?(result, options = {})
    id = result.engine_id
    !(["more", "resource_types"].include?(id) &&
       total_items(result) == 0) &&
    !(is_child_box?(id) && !options[:render_child_box])
  end

  def bento_titleize(id)
    engine = BentoSearch.get_engine(id)
    if id == "books_and_media"
      link_to "Books & Media", engine.url(self), id: "bento_" + id + "_header"
    elsif id == "lib_guides"
      link_to "Research Guides", engine.url(self), id: "bento_" + id + "_header"
    elsif id == "cdm"
      link_to "Digital Collections", engine.url(self), id: "bento_" + id + "_header"
    else
      link_to id.titleize , engine.url(self), id: "bento_" + id + "_header"
    end
  end

  def render_bento_results(results = @results, options = {})
    results_class = options[:results_class] || "d-md-flex flex-wrap"
    comp_class = options[:comp_class] || "bento_compartment p-2 mt-4 mr-4"

    render partial: "bento_results", locals: {
      results_class: results_class,
      comp_class: comp_class,
      results: results, options: options }
  end

  def render_linked_results(engine_id)
    engine_ids = engine_display_configurations[engine_id][:linked_engines] || [] rescue []
    results = @results.select { |id, result| engine_ids.include? id }
    render_bento_results(results, render_child_box: true, results_class: "bento_results", comp_class: "bento_compartment")
  end

  def is_child_box?(id)
    linked_engines.include? id
  end

  def linked_engines
    engine_display_configurations.select { |id, config| config[:linked_engines] }
      .map { |id, config| config[:linked_engines] }
      .flatten
  end

  def engine_display_configurations
    @engine_configurations ||= @results.map   { |engine_id, result|
      config = BentoSearch.get_engine(engine_id).configuration[:for_display]
      [engine_id, config]
    }.to_h
  end

  def cdm_collection_name(cdm_alias)
    cdm_url = "https://digital.library.temple.edu/digital/bl/dmwebservices/index.php?q=dmGetCollectionList/json"
    response = JSON.load(URI.open(cdm_url))
    collection = response.select { |collection| collection["name"] if collection["alias"] == cdm_alias }
    collection.first["name"]
  end
end
