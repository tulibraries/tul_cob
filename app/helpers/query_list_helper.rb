# frozen_string_literal: true

module QueryListHelper
  def query_list(title, tooltip, query, footer_field = nil)
    if @document&.id
      query += "&filter_id=#{@document.id}"
    end

    if footer_field
      query += "&footer_field=#{footer_field}"
    end

    title = link_to title, search_catalog_path + "?#{query}"

    render partial: "query_list/results", locals: { query: query + "&per_page=5", title: title, tooltip: tooltip }
  end

  def query_list_footer_value(document, field)
    if document[field]&.include?(0)
      document[field].delete(0)
    end

    value = document[field]&.first

    case field
    when "date_added_facet"
      begin
        Date.parse("#{value}").strftime("%Y-%m-%d")
      rescue => e
        Honeybadger.notify("Error trying to parse date_added_facet value; @htomren " + "#{e.message}")
        ""
      end
    else
      value
    end
  end

  def creator_query_list(document)
    field = "creator_display"
    creator = document[field]&.first&.split("|")&.first
    query_list(
      title = "By author/creator",
      tooltip = t("tooltip.creator"),
      query = "f[creator_facet][]=#{creator}&sort=pub_date_sort+desc,+title_sort+asc", footer_field = "pub_date"
    ) unless creator.blank?
  end

  def call_number_query_list(document, order = "asc")
    field = "lc_call_number_display"
    lc_call_number = document["lc_call_number_display"]&.first&.gsub(/\s+/, "")
    # This is built this way due to a possible bug with desc lc_call_number sorts
    # We may need to refactor this when that bug is fixed
    # We think the bug is in the add_lc_range_search_to_solr method
    position = order == "asc" ? "begin" : "end"
    call_number_title = order == "asc" ? "By call number (a-z)" : "By call number (z-a)"
    tooltip = order == "asc" ? t("tooltip.call_number_asc") : t("tooltip.call_number_desc")
    query_list(
      title = call_number_title,
      tooltip = tooltip,
      query = "f_1=all_fields&f_2=all_fields&f_3=all_fields&op_1=AND&op_2=AND&operator%5Bq_1%5D=contains&operator%5Bq_2%5D=contains&operator%5Bq_3%5D=contains&q_1=&q_2=&q_3=&range%5Blc_classification%5D%5B#{position}%5D=#{lc_call_number}&range%5Bpub_date_sort%5D%5Bbegin%5D=&range%5Bpub_date_sort%5D%5Bend%5D=&search_field=advanced&sort=lc_call_number_sort+#{order}%2C+pub_date_sort+desc", footer_field = field
    ) unless lc_call_number.blank?
  end

  def libraries_query_display(document)
    libraries = document["library_facet"]
    unless libraries.nil?
      if libraries.count > 2
        html = content_tag(:p, libraries.first, class: "mb-0 pb-0 text-truncate")
        html += content_tag(:p, "More Locations", class: "mb-0 pb-0 font-italic")
      elsif libraries.count === 2
        content_tag(:p, libraries.join("<br />").html_safe, class: "mb-0 pb-0 text-truncate")
      else
        content_tag(:p, libraries.join("<br />").html_safe, class: "mb-0 pb-0")
      end
    end
  end

  def query_list_view_more_links(query_params)
    link_to "View More", search_catalog_path(query_params.except(:per_page)), class: "query-list-view-more stretched-link"
  end
end
