class CommentsController < ApplicationController

  def create
    @post = Post.find(params[:post_id])
    @comment = @post.comments.build(params[:comment])
    @comment.user = current_or_guest_user

    if @comment.save
      flash[:success] = 'Your comment has been posted'
      flash.keep
      redirect_to @post
    else
      @post = Post.find(params[:post_id])
      render 'posts/show'
    end
  end
end
