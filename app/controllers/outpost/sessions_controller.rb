class Outpost::SessionsController < Outpost::BaseController  
  skip_before_filter :require_admin
  respond_to :html
  
  def new
    redirect_to outpost.root_path if admin_user
  end
  
  def create
    if user = AdminUser.authenticate(params[:username], params[:unencrypted_password])
      session['_auth_user_id'] = user.id
      # For Django
      session['_auth_user_backend'] = 'django.contrib.auth.backends.ModelBackend'
      user.update_attribute(:last_login, Time.now)
      redirect_to session[:return_to] || outpost.root_path, notice: "Logged in."
    else
      flash.now[:alert] = "Invalid login information."
      render 'new'
    end    
  end
  
  def destroy
    @admin_user = nil
    session['_auth_user_id'] = nil
    redirect_to outpost_login_path, notice: "Logged Out."
  end
end
