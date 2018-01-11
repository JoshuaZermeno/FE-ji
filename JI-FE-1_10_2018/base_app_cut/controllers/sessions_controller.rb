class SessionsController < ApplicationController
	include SessionsHelper

  def create 
    @employee = Employee.find(params[:session][:id])
    if @employee && @employee.authenticate(params[:session][:password])
	    if @employee.status == "Terminated"
	      flash.now[:title] = "Error"
	      flash.now[:notice] = "Access Denied: Please contact Human Resources at 419-661-5276."
	      render action: :new
	    else
	      log_in @employee
	      flash[:title] = "Success"
	      flash[:notice] = "Login Successful."
	      redirect_to action: :index
	    end
	  else
	  	flash.now[:title] = "Error"
      flash.now[:notice] = "Incorrect ID number and password combination"
      render action: :new
	  end

    rescue ActiveRecord::RecordNotFound
      flash.now[:title] = "Error"
      flash.now[:notice] = "Access Denied: Invalid ID number"
      render 'new'
  end

  def create_swiped
    swipeRegex = "%[0-9]{9}?"
    if params[:session][:id_swiped].match(swipeRegex)
        extracted_id = params[:session][:id_swiped].split(%r{[%?;]})[1]
        @employee = Employee.find(extracted_id)
        log_in_limited @employee
        redirect_to controller: :employees, action: :home
    else
      flash.now[:title] = "Error"
      flash.now[:notice] = "Please swipe again or try logging in via IDnum and password using the login button below"
      render 'new_swipe'
    end
  end

  def destroy
    log_out
    flash[:title] = "Success"
    flash[:notice] = "Logout successful"
    redirect_to login_url
  end

  def index
  		authenticate_user_logged_in
  end

  def new

  end

  def new_swipe

  end

end
