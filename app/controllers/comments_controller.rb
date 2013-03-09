class CommentsController < ApplicationController

  before_filter :authenticate_user!, only: [:create]

  def create
    @post = Post.find(params[:post_id])
    @comment = @post.comments.build(params[:comment])
    @comment.user = current_user

    if @comment.save
      flash[:success] = 'Your comment has been posted'
      redirect_to @post
    else
      @post = Post.find(params[:post_id])
      render 'posts/show'
    end
  end
end
