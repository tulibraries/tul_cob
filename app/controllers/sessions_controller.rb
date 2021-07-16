# frozen_string_literal: true

class SessionsController < Devise::SessionsController
  include Sessions::SocialLogin

  before_action :get_manifold_alerts, only: [ :new ]

  layout proc { |controller| false if request.xhr? }

  # Overrides Devise::SessionsController#new.
  def new
    @document = SolrDocument.find(params[:redirect_to].rpartition("doc-")) rescue SolrDocument.new({})
    no_cache unless request.xhr?.nil?
    super
  end
end
