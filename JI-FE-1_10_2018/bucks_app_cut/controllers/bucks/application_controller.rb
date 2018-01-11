module Bucks
	class ApplicationController < ::ApplicationController
		include SessionsHelper

	  protect_from_forgery with: :exception

	  def authenticate_user_logged_in
		  if session[:id] 
		  	if session[:expires_at] < Time.current
		  		log_out_timed
		    	return false
		  	else
		  		# Global variables
		  		@current_user = ::Employee.find(session[:id])
		  		@global_orders = Bucks::Purchase.where(status: 'Ordered').joins('INNER JOIN employees 
		  			ON bucks_purchases.employee_id = employees.IDnum').where('employees.property_id = ?', session[:property])
		    	return true	
		  	end
		  else
		  	flash[:title] = "Error"
		  	flash[:notice] = "Login Required"
		    redirect_to '/login'
		    return false
		  end
		end	

		def authenticate_user_is_admin
			if ::Employee.find(session[:id]).job.bucks_admin
				return true
			else
				flash[:title] = "Error"
		  	flash[:notice] = "You do not have access to that feature."
		    redirect_to controller: :employees, action: :show, id: session[:id]
		    return false
			end
		end	
	end
end