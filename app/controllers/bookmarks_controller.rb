# frozen_string_literal: true

class BookmarksController < CatalogController
  include Blacklight::Bookmarks

  # Overridden to not cache.
  def index
    no_cache
    super
  end

  def create
    super
    set_guest_bookmark_warning
  end

  def destroy
    super
    set_guest_bookmark_warning
  end

  private

    def set_guest_bookmark_warning
      return if request.xhr? || current_user.present?

      flash.discard(:notice)
      flash.discard(:error)
      flash[:alert] = I18n.t("blacklight.bookmarks.guest_warning")
    end
end
