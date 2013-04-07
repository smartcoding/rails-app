class TagsController < ApplicationController
  # Render /origins.json and /tags.json
  def index
    tags = ActsAsTaggableOn::Tag
            .includes(:taggings)
            .where("taggings.context = ?", params[:tag_type])
            .where("name like ?", "%#{params[:q]}%")
            .select(:name)
            .paginate(page: params[:page],
                      order: 'tags.name ASC',
                      per_page: params[:per_page])

    respond_to do |format|
      format.json {
        render :json => {
          :total => tags.count,
          :result => tags.map { |t| t.name }
        }
      }
    end
  end

  def show
    if params[:tag]
      @posts = Post.tagged_with(params[:tag], on: :tags).popular(params)
    elsif params[:origin]
      @posts = Post.tagged_with(params[:origin], on: :origins).popular(params)
    else
      @posts = Post.popular(params)
    end
    render 'posts/posts'
  end
end
