class UsersController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  before_action :require_open_registration, only: %i[ new create ]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      start_new_session_for(@user) unless authenticated?
      redirect_to root_path, notice: "User saved."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def require_open_registration
      return if User.none?

      require_authentication
    end

    def user_params
      params.require(:user).permit(:email_address, :password, :password_confirmation)
    end
end
