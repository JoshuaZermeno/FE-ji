module SessionsHelper

  def is_store_open
    return Time.now.getlocal("-04:00").hour.between?(9, 17) 
  end

	def log_in(employee)
    session[:id] = employee.id
    session[:expires_at] = Time.current + 1.hours
    session[:property] = employee.property_id
  end

  def log_in_extended(employee)
    session[:id] = employee.id
    session[:expires_at] = Time.current + 1.hours
    session[:property] = employee.property_id
  end

  def log_in_limited(employee)
    session[:id] = employee.id
    session[:expires_at] = Time.current + 1.hours
    session[:property] = employee.property_id
  end

  def log_out
    session.clear
    @current_user = nil
  end

  def log_out_timed
    session.clear
    flash[:title] = "Error"
    flash[:notice] = "Session has expired. Please log or swipe in."
    @current_user = nil
    redirect_to '/login' # Root app login
  end

  def current_user
    @current_user ||= Employee.find_by(id: session[:id])
  end

  def logged_in?
    !current_user.nil?
  end

  def destroy
    log_out
  end

end
