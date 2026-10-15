# frozen_string_literal: true

class SessionsController < Devise::SessionsController
  include LoginCookie
  include Sessions::SocialLogin

  before_action :get_manifold_alerts, only: [ :new ]
  before_action :permit_session_parameters, only: %i[new create social_login_callback]

  layout proc { |controller| false if request.xhr? }

  # Overrides Devise::SessionsController#new.
  def new
    doc_id = SolrDocument.sanitize_id(params[:redirect_to])
    @document = SolrDocument.find(doc_id) rescue SolrDocument.new({})
    flash.now[:alert] = t("blacklight.tools.email_login_required_notice") if params[:login_message] == "email"
    no_cache unless request.xhr?.nil?
    super
  end

  def create
    super { |user| set_login_cookie(user) }
  end

  def after_sign_in_path_for(resource)
    params[:redirect_to].presence || super
  end

  def destroy
    clear_login_cookie
    super
  end

  private

    def params
      @permitted_session_params || super
    end
    public :params

    def permit_session_parameters
      @permitted_session_params = if action_name == "social_login_callback"
        params.permit(:jwt, :redirect_to)
      else
        params.permit(
          :redirect_to,
          :login_message,
          user: %i[email password password_confirmation remember_me]
        )
      end
    end
end
