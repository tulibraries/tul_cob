# frozen_string_literal: true

class FacetItemPresenter < Blacklight::FacetItemPresenter
  # If we are rendering a more general facet in a state
  # where a more specific facet is selected, we are
  # effectively offering the user a chance to cancel the
  # specific facet and replace it with the more general facet.
  # So we don't want the specific one sticking around.
  def hide_facet_param(facet_item)
    @hidden_facet_params ||= []
    @hidden_facet_params << facet_item
  end

  def hidden_facet_params
    @hidden_facet_params || []
  end

  def keep_in_params!
    @keep_in_params ||= true
  end

  def keep_in_params?
    @keep_in_params
  end

  def remove_href(path = search_state)
    if keep_in_params?
      search_path(path.remove_facet_params(nil, nil))
    else
      search_path(path.remove_facet_params(facet_config.key, facet_item))
    end
  end

  def add_href(path_options = {})
    if facet_config.url_method
      view_context.public_send(facet_config.url_method, facet_config.key, facet_item)
    else
      search_path(search_state.add_facet_params_and_redirect(facet_config.key, facet_item).merge(path_options))
    end
  end

  def search_path(path)
    hidden_facet_params.each do |hidden_facet_param|
      path["f"]&.delete(hidden_facet_param.field)
    end
    view_context.search_action_path(path)
  end
end
