class PostsController < ApplicationController
  impressionist :unique => [:impressionable_type, :impressionable_id,
                            :session_hash],
                :actions => [:show]

  def index
    redirect_to popular_url, :status => 302
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
    @post = current_or_guest_user.posts.build(params[:post])
    if @post.save
      flash[:success] = 'Your post has been posted!'
      flash.keep
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
    @post = current_or_guest_user.posts.find(params[:id])
  end

  def update
    @post = current_or_guest_user.posts.find(params[:id])

    if @post.update_attributes(params[:post])
      flash[:success] = 'Your post was updated'
      flash.keep
      redirect_to @post
    else
      render :edit
    end
  end

  def search
    @posts = Post.search(params)
  end
end
