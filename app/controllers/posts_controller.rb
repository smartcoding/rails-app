class PostsController < ApplicationController
  before_filter :auth, only: [:create]
  def index
    @post = Post.new
    @posts = Post.latest(params)
  end

  def create
    @post = current_user.posts.build(params[:post])
    if @post.save
      flash[:success] = 'Your post has been posted!'
      redirect_to root_url
    else
      @posts = Post.latest(params)
      render :index
    end
  end
end
