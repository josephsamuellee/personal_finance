class ApplicationController < ActionController::Base
  include Authentication

  default_form_builder UiFormBuilder
  before_action :mirror_appearance_cookie

  private
    def mirror_appearance_cookie
      return unless current_user

      cookies.permanent[:appearance] = { value: current_user.appearance, httponly: true, same_site: :lax }
    end
end
