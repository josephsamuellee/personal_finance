class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]

  def new
  end

  def create
    user = User.authenticate_by(email_address: params[:email_address], password: params[:password])
    if user
      start_new_session_for(user)
      redirect_to root_path, notice: "Signed in."
    else
      flash.now[:alert] = "That email or password is incorrect."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, notice: "Signed out."
  end
end
