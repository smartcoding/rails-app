class UsersController < ApplicationController
  before_filter :authenticate_user!, only: [:following, :flow]

  def show
    @user = User.find(params[:id])
    @posts = @user.your_posts(params)
  end

  def following
    @posts = current_user.following_feed(params)
  end

  def activity
    @user = User.find(params[:id])
    @timelines = @user.your_timelines(params)
  end

  def flow
    @timelines = current_user.flow_feed(params)
  end
end
