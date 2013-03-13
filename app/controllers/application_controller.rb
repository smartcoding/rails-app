class ApplicationController < ActionController::Base
  protect_from_forgery
  helper_method [:current_or_guest_user, :current_or_guest_user?, :guest_user?]
  # This method will trigger a notice if Guest Account was removed/expired
  before_filter :current_or_guest_user?
  # This method will move all guest actions to signed in user
  before_filter :upgrade_guest_user

  # Only returns User model if user is logged in or is in Guest mode
  def current_or_guest_user?
    @cached_current_or_guest_user ||= current_user || guest_user?
  end

  # Returns existing User model if logged in or in Guest mode
  # and creates new record if otherwise
  # Also if it detects that user is logged in and has Guest history, then
  # it moves Guest history to his current User
  def current_or_guest_user
    current_user || guest_user
  end

  def upgrade_guest_user
    if current_user && cookies[:guest_user_id]
      guest_user.move_to current_user
      cookies.delete :guest_user_id # The cookie is also irrelevant now
    end
  end

  # find guest_user object associated with the current session,
  # creating one as needed
  def guest_user
    @cached_guest_user ||= User.find(cookies[:guest_user_id] ||= create_guest_user.id)

  rescue ActiveRecord::RecordNotFound # if cookies[:guest_user_id] invalid
    cookies.delete :guest_user_id
    flash.now[:guest_expired] = "Your old Guest account expired"
    guest_user
  end

  # return User model if Guest user is found
  # nil - if otherwise
  def guest_user?
    return nil unless cookies[:guest_user_id]
    @cached_guest_user ||= User.find(cookies[:guest_user_id])

  rescue ActiveRecord::RecordNotFound # if cookies[:guest_user_id] invalid
      cookies.delete :guest_user_id
      flash.now[:guest_expired] = "You old Guest account expired"
      nil
  end

  protected

  # called as before_filter in
  # omniauth_email_controller and omniauth_password_controller
  def verify_omniauth_session
    @attributes = session["devise.user_attributes"]
    if @attributes.nil?
      redirect_to root_path
    end
  end

  private

  # called (once) when the user logs in, insert any code your application needs
  # to hand off from guest_user to current_user.
  def logging_in
    # What should be done here is take all that belongs to guest user and
    # assign it to current_user
    # For example:
    # guest_likes = guest_user.likes.all
    # guest_likes.each do |like|
      # like.user_id = current_user.id
      # like.save!
    # end
  end

  def create_guest_user
    u = User.create(:guest => true,
                    :email => "guest_#{Time.now.to_i}#{rand(99)}@example.com",
                    :username => "guest_#{Time.now.to_i}#{rand(99)}")
    cookies[:guest_user_id] = { :value => u.id, :path => '/', :expires => 5.years.from_now }
    flash.now[:new_guest] = "You were granted with new Guest user, enjoy!"
    u
  end
end
