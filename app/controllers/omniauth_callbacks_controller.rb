class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def github

    omniauth = request.env["omniauth.auth"]
    provider = omniauth["provider"]
    uid      = omniauth["uid"]

    if user_signed_in?
      # user is trying to connect service to his existing account?

      auth = Service.find_by_provider_and_uid(provider, uid)
      if auth.nil?
        current_user.services.build(:provider => provider, :uid => uid)
        flash[:notice] = 'Sign in via ' + provider.capitalize + ' has been added to your account.'
        redirect_to edit_user_registration_path
      else
        flash[:notice] = provider.capitalize + ' is already linked to your account.'
        redirect_to edit_user_registration_path
      end

    else
      # the user is not signed in

      user = User.from_omniauth(omniauth)
      if user.persisted?
        flash.notice = t 'devise.registrations.signed_up'
        sign_in_and_redirect user
      else
        if user.errors[:email][0] =~ /has already been taken/
          session["devise.user_attributes"] = user.attributes
          redirect_to auth_login_path(:email => user.email)
        elsif user.errors[:email][0] =~ /can't be blank/
          session["devise.user_attributes"] = user.attributes
          redirect_to auth_email_path
        else
          flash[:notice] = "Sorry, we couldn't connect your #{provider} account"
          redirect_to root_path
        end
      end

    end
  end
end
