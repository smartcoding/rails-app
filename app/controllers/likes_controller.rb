class LikesController < ApplicationController
  before_filter :auth

  def create
    @post = Post.find(params[:id])
    current_user.add_like_to_post!(@post)
    redirect_to @post
  end

  def destroy
    @post = Post.find(params[:id])
    current_user.unlike_a_post!(@post)
    redirect_to @post
  end
end
