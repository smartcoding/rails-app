class OmniauthEmailController < ApplicationController
  before_filter :verify_omniauth_session

  def new
    @user = User.new(@attributes, :without_protection => true)
  end

  def create
    @attributes["email"] = params[:email]
    @user = User.new(@attributes, :without_protection => true)
    if @user.save
      flash.notice = t 'devise.registrations.signed_up'
      sign_in_and_redirect @user
    else
      @attributes["email"] = nil
      if @user.errors[:email][0] =~ /has already been taken/
        redirect_to auth_login_path(:email => params[:email])
      else
        render :action => :new
      end
    end # @user.save
  end
end
