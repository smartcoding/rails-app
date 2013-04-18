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
    if @post.save and @post.create_repository(current_or_guest_user)
      flash[:success] = "Your #{@post.category.to_s} has been posted!"
      flash.keep
      redirect_to @post
    else
      render 'posts/new'
    end
  end

  def show
    @post = Post.find(params[:id])

    repo = Rugged::Repository.new "./posts/#{params[:id]}"
    master = Rugged::Branch.lookup(repo, "master")

    master.tip.tree.each_blob do |b|
      @body = repo.lookup(b[:oid]).content if b[:name] === "#{@post.category.to_s}.md"
      @answer = repo.lookup(b[:oid]).content if b[:name] === "answer.md"
      @solution = repo.lookup(b[:oid]).content if b[:name] === "solution.md"
      if b[:name] === "META.yml"
        meta = repo.lookup(b[:oid]).content
        if meta
          yaml = YAML.load meta
          @tags = yaml["tags"]
          @origins = yaml["origins"]
        end
      end
    end

    @comment = Comment.new
  end

  def edit
    @post = Post.find(params[:id])
  end

  def update
    @post = Post.find(params[:id])

    if @post.user === current_or_guest_user
      if @post.update_attributes(params[:post]) and @post.commit_changes
        flash[:success] = "The #{@post.category.to_s} was updated"
        flash.keep
        redirect_to edit_post_path @post
      else
        render :edit
      end
    else
      if @post.submit_patch(current_or_guest_user, params[:post])
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

  # /posts/:id/pull/:pull_id
  def pull
    @post = Post.find(params[:id])

    g = Git.bare "./posts/#{params[:id]}"

    if g.branches.to_s.match(/#{params[:pull_id]}/).nil?
      flash[:warning] = "No such pull request was found"
      redirect_to post_path @post and return
    end

    @diff = g.diff("#{params[:pull_id]}~", params[:pull_id])

    # check patch status
    g.with_temp_working do
      g.reset_hard 'master'
      begin
        @mergeable = g.patch_mergeable? 'master', params[:pull_id]
      rescue => e
      end
      render :pull and return
    end
  end

  def pull_merge
    @post = Post.find(params[:id])
    @patch = Patch.find(params[:pull_id])
    repo = Rugged::Repository.new "./posts/#{params[:id]}"

    if @post.user === current_or_guest_user
      g = Git.bare "./posts/#{params[:id]}"
      g.with_temp_working do
        # g.config('user.name', 'Robot')
        # g.config('user.email', 'email@email.com')
        # g.merge(params[:pull_id], "Merge pull request ##{params[:pull_id]}")
        g.reset_hard 'master'
        begin
          raise unless g.patch_mergeable? 'master', params[:pull_id]
          g.apply_patch 'master', @patch.id
          # g.branch(params[:pull_id]).delete

          # Retrieve the latest Repo status
          master = Rugged::Branch.lookup(repo, "master")
          master.tip.tree.each_blob do |b|
            @body = repo.lookup(b[:oid]).content if b[:name] === "#{@post.category.to_s}.md"
            @description = repo.lookup(b[:oid]).content if b[:name] === "README.md"
            @answer = repo.lookup(b[:oid]).content if b[:name] === "answer.md"
            @solution = repo.lookup(b[:oid]).content if b[:name] === "solution.md"
            if b[:name] === "META.yml"
              meta = repo.lookup(b[:oid]).content
              if meta
                yaml = YAML.load meta
                @tags = yaml["tags"]
                @origins = yaml["origins"]
              end
            end
          end

          # Update the Model
          @post.body = @body
          @post.description = @description
          @post.answer = @answer if @answer
          @post.solution = @solution if @solution
          @post.tag_list = @tags
          @post.origin_list = @origins
          @post.save

          @patch.is_merged!
          @patch.save

          flash[:notice] = "Merged!"
        rescue => e
          flash[:warning] = "This patch cannot be merged automatically"
        end
        redirect_to "/posts/#{params[:id]}/pull/#{params[:pull_id]}" and return
      end
    else
      flash[:warning] = "You have no permission for this action"
      redirect_to "/posts/#{params[:id]}/pull/#{params[:pull_id]}" and return
    end
  end

  private 

  def verify_selected_post_category
    @category = params[:category]
    if Post.categories[ @category ].nil?
      redirect_to new_post_path(:category => Post.categories.first[0])
    end
  end
end
