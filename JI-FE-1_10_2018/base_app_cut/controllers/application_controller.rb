class ApplicationController < ActionController::Base
		include SessionsHelper
	  # Prevent CSRF attacks by raising an exception.
	  # For APIs, you may want to use :null_session instead.
	  protect_from_forgery with: :exception

	  def authenticate_user_logged_in
		  if session[:id] 
		  	if session[:expires_at] < Time.current
		  		log_out_timed
		    	return false
		  	else
		  		@current_user = ::Employee.find(session[:id])
					@current_user_job = ::Job.find_by(jobcode: @current_user.job_id)
					@current_user_department = ::Department.find(@current_user.department_id)
		    	return true	
		  	end
		  else
		  	flash[:title] = "Error"
		  	flash[:notice] = "Login Required"
		    redirect_to controller: :sessions, action: :new
		    return false
		  end
		end	
end
