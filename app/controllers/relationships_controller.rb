class RelationshipsController < ApplicationController
  def create
    @user = User.find_by_username!(params[:id])
    current_or_guest_user.follow!(@user) unless @user == current_or_guest_user
    flash.keep
    redirect_to request.referer
  end

  def destroy
    @user = User.find_by_username!(params[:id])
    current_or_guest_user.unfollow!(@user)
    flash.keep
    redirect_to request.referer
  end
end
