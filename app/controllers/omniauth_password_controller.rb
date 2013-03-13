class OmniauthPasswordController < ApplicationController
  before_filter :verify_omniauth_session

  def new
    @user = User.find_by_email(params[:email])
  end

  def create
    @user = User.find_by_email(params[:email])
    if @user.valid_password? params[:password]
      @user.update_attributes(:provider => @attributes["provider"], :uid => @attributes["uid"])
      flash[:notice] = "Hooray, you just connected you github account and signed in"
      sign_in_and_redirect @user
    else
      @user.errors.add(:password, "Not vaild")
      render :action => :new
    end
  end
end
