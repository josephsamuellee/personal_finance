class SettingsController < ApplicationController
  def show
  end

  def update
    appearance = params[:appearance].to_s
    unless User::APPEARANCES.include?(appearance)
      redirect_to settings_path, alert: "Choose light, dark, or system."
      return
    end

    current_user.update!(appearance:)
    cookies.permanent[:appearance] = { value: appearance, httponly: true, same_site: :lax }
    redirect_to settings_path, notice: "Appearance saved."
  end
end
