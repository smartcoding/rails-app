class UsersController < ApplicationController

  def show
    @user = User.find_by_username!(params[:id])
    @posts = @user.your_posts(params)
  end

  def activity
    @user = User.find_by_username!(params[:id])
    @timelines = @user.your_timelines(params)
  end

  def flow
    @timelines = current_or_guest_user?.try(:flow_feed, params)
    if @timelines.nil?
      @users = User.where(guest: nil)
    elsif @timelines.count == 0 && user_signed_in?
      @users = User.where(guest: nil).where("id <> ?", current_user.id)
    end
  end

  def omniauth
    user = User.from_omniauth(env["omniauth.auth"])
    sign_in(user)
    flash[:hey] = "Congratulations! You've signed in as #{user.username}!"
    redirect_to popular_path
  end

  def omniauth_fail
    flash[:oops] = "Oops, did not went well this time.."
    redirect_to login_path
  end
end
