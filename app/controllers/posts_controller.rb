class PostsController < ApplicationController
  before_filter :auth, only: [:create, :your_posts, :edit, :update]
  def index
    @post = Post.new
    @posts = Post.latest(params)
  end

  def create
    @post = current_user.posts.build(params[:post])
    if @post.save
      flash[:success] = 'Your post has been posted!'
      redirect_to @post
    else
      @posts = Post.latest(params)
      render :index
    end
  end

  def show
    @post = Post.find(params[:id])
    @comment = Comment.new
  end

  def your_posts
    @posts = current_user.your_posts(params)
  end

  def edit
    @post = current_user.posts.find(params[:id])
  end

  def update
    @post = current_user.posts.find(params[:id])

    if @post.update_attributes(params[:post])
      flash[:success] = 'Your post was updated'
      redirect_to @post
    else
      render :edit
    end
  end

  def search
    @posts = Post.search(params)
  end
end
