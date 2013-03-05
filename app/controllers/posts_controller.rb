class PostsController < ApplicationController
  before_filter :auth, only: [:new, :create, :edit, :update]

  def index
    if logged_in?
      redirect_to following_url, :status => 302
    else
      redirect_to popular_url, :status => 302
    end
  end

  def popular
    @posts = Post.popular(params)
    render :posts
  end

  def fresh
    @posts = Post.latest(params)
    render :posts
  end

  def new
    @post = Post.new
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
