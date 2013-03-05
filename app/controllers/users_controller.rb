class UsersController < ApplicationController
  before_filter :auth, only: [:following]

  def new
    @user = User.new
  end

  def create
    @user = User.new(params[:user])
    if @user.save
      login @user
      flash[:success] = 'Thanks for registering!'
      redirect_to root_url
    else
      render 'new'
    end
  end

  def show
    @user = User.find(params[:id])
    @posts = @user.your_posts(params)
  end

  def following
    @posts = current_user.following_feed(params)
  end
end
