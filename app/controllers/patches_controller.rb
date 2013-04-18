class PatchesController < ApplicationController
  def show
    @post = Post.find(params[:post_id])
    @patch = Patch.find(params[:id])

    g = Git.bare "./posts/#{@post.id}"

    if g.branches.to_s.match(/#{@patch.id}/).nil?
      flash[:warning] = "No such patch was found"
      redirect_to post_path @post and return
    end

    @diff = g.diff("#{@patch.id}~", @patch.id)

    # check patch status
    g.with_temp_working do
      g.reset_hard 'master'
      begin
        @mergeable = g.patch_mergeable? 'master', @patch.id
      rescue => e
      end
      return
    end
  end

  def merge
    @post = Post.find(params[:post_id])
    @patch = Patch.find(params[:patch_id])

    repo = Rugged::Repository.new "./posts/#{@post.id}"

    if @post.user === current_or_guest_user
      g = Git.bare "./posts/#{@post.id}"
      g.with_temp_working do
        # g.config('user.name', 'Robot')
        # g.config('user.email', 'email@email.com')
        # g.merge(params[:pull_id], "Merge pull request ##{params[:pull_id]}")
        g.reset_hard 'master'
        begin
          raise unless g.patch_mergeable? 'master', @patch.id
          g.apply_patch 'master', @patch.id
          # g.branch(@patch.id).delete

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
        redirect_to post_patch_path @post, @patch and return
      end
    else
      flash[:warning] = "You have no permission for this action"
      redirect_to post_patch_path @post, @patch and return
    end
  end
end
