class ConfirmationsController < Devise::ConfirmationsController

  def create
    if signed_in?
      if User.find_by_email(params[:user][:email]).nil?
        current_user.update_column(:email, params[:user][:email])
        super
      else
        flash[:notice] = "Email is already taken"
        redirect_to :back
      end
    else
      super
    end
  end

  protected

  def after_resending_confirmation_instructions_path_for(resource_name)
    if signed_in?
      flash[:notice] = "Activation email re-sent to: #{current_user.email}. Please check your mailbox"
     root_path
    else
      super
    end
  end
end
