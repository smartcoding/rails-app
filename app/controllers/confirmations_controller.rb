class ConfirmationsController < Devise::ConfirmationsController

  def create
    if signed_in?
      current_user.update_column(:email, params[:user][:email])
    end
    super
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
