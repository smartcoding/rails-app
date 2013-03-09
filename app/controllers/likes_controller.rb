class LikesController < ApplicationController
  def create
    @post = Post.find(params[:id])
    current_or_guest_user.add_like_to_post!(@post) unless @post.user == current_or_guest_user
    flash.keep
    redirect_to @post
  end

  def destroy
    @post = Post.find(params[:id])
    current_or_guest_user.unlike_a_post!(@post)
    flash.keep
    redirect_to @post
  end
end
