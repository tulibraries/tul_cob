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

  def search_state
    @hidden_facet_params ||= []
    Blacklight::SearchState.new(
      @hidden_facet_params.reduce(super) { |_search_state, facet_item| _search_state.remove_facet_params(facet_item.field, facet_item) },
      view_context.blacklight_config
    );
  end

  def keep_in_params!
    @keep_in_params ||= true
  end

  def keep_in_params?
    @keep_in_params
  end

  def href(path_options = {})
    if selected? && keep_in_params?
      view_context.search_action_path(search_state)
    else
      super
    end
  end
end
