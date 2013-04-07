class PostsController < ApplicationController
  impressionist :unique => [:impressionable_type, :impressionable_id,
                            :session_hash],
                :actions => [:show]

  before_filter :verify_selected_post_category, :only => [:new]

  def index
    flash.keep
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
    @post.category = @category
  end

  def create
    @post = current_or_guest_user.posts.build(params[:post])
    if @post.save and @post.create_repository
      flash[:success] = "Your #{@post.category.to_s} has been posted!"
      flash.keep
      redirect_to @post
    else
      render 'posts/new'
    end
  end

  def show
    @post = Post.find(params[:id])

    require 'rugged'
    repo = Rugged::Repository.new "./posts/#{params[:id]}"
    master = repo.lookup Rugged::Branch.lookup(repo, "master").target

    master.tree.each_blob do |b|
      @body = repo.lookup(b[:oid]).content if b[:name] === "#{@post.category.to_s}.md"
      @answer = repo.lookup(b[:oid]).content if b[:name] === "answer.md"
      @solution = repo.lookup(b[:oid]).content if b[:name] === "solution.md"
      @meta = repo.lookup(b[:oid]).content if b[:name] === "META.yml"
    end

    require 'yaml'
    if @meta
      yaml = YAML.load @meta
      @tags = yaml["tags"]
      @origins = yaml["origins"]
    end

    @comment = Comment.new
  end

  def edit
    @post = Post.find(params[:id])
  end

  def update
    @post = Post.find(params[:id])

    if @post.user === current_or_guest_user
      if @post.update_attributes(params[:post]) and @post.commit_changes(params[:post])
        flash[:success] = "The #{@post.category.to_s} was updated"
        flash.keep
        redirect_to edit_post_path @post
      else
        render :edit
      end
    else
      if @post.submit_pull_request(current_or_guest_user, params[:post])
        flash[:success] = "Your changes were submitted for moderation"
        flash.keep
        redirect_to edit_post_path @post
      else
        render :edit
      end
    end
  end

  def search
    @posts = Post.search(params)
  end

  private 

  def verify_selected_post_category
    @category = params[:category]
    if Post.categories[ @category ].nil?
      redirect_to new_post_path(:category => Post.categories.first[0])
    end
  end
end
