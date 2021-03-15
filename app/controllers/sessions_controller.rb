# frozen_string_literal: true

class SessionsController < Devise::SessionsController
  include Sessions::SocialLogin

  layout proc { |controller| false if request.xhr? }

  # Overrides Devise::SessionsController#new.
  def new
    @document = SolrDocument.find(params[:redirect_to].rpartition("doc-").last) rescue [ nil, SolrDocument.new({}) ]
    no_cache unless request.xhr?.nil?
    super
  end
end
