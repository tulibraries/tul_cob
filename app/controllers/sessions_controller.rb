# frozen_string_literal: true

class SessionsController < Devise::SessionsController
  include BlacklightAlma::SocialLogin

  layout proc { |controller| false if request.xhr? }
end
