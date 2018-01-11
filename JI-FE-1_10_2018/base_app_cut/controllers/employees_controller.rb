class EmployeesController < ApplicationController
	include SessionsHelper

  APP_URL_BUCKS = "http://bucks.hollywoodcasinotoledo.org/api/v1/sync"
	APP_URL_LOCAL = "http://localhost:3000/api/v1/sync"

	COLUMN_EMPLOYEE_NUMBER = 0
	COLUMN_EMPLOYEE_NAME = 1
	COLUMN_JOB_CODE = 2
	COLUMN_JOB_TITLE = 3
	COLUMN_DEPARTMENT = 4
	COLUMN_STATUS = 5
	COLUMN_HIRED = 6
	COLUMN_EMAIL = 7

	require 'uri'
	require 'net/http'
	require 'net/https'

	# .com/api/login				API LOGIN
	# For token creation when attemping to access the apps via a mobile device through the API
	# Upon valid verification of ID number and password, a newly created API token will be saved
	# and sent back to all apps and their APIs for quick authentication specific to the app.
	# Returns API token
  def api_login
    employee = Employee.find_by(IDnum: params[:IDnum])
    if employee && employee.authenticate(params[:password])
    	if employee.status = "Active"
    		token = employee.generate_api_token
      	distribute_api_token(employee.IDnum, token)
      	render(json: {"api_token" => employee.api_token}.to_json, status: 201)
    	else
    		msg = { :status => "ERROR", :message => "Access Denied: No longer active employee" }
      	render :json => msg, status: :forbidden
    	end
    else
      msg = { :status => "ERROR", :message => "Invalid ID number and password combination" }
      render :json => msg, status: :forbidden
    end
  end

  def distribute_api_token(idnum, token)
  	payload = {"IDnum" => idnum}
  	headers = {"Authorization" => "Token token=" + token.to_s + ",IDnum=" + idnum.to_s}
  	uri = URI.parse(APP_URL_BUCKS)
  	http = Net::HTTP.new(uri.host, uri.port)
  	# http.use_ssl = true
  	req = http.post(uri.path, nil, headers)
  end

  # .com/verify				WEBSITE LOGIN
  # For basic website login verification
  # Simply finds the employee, verifies password, and returns appropriate status code and throws back key
	def web_login
		employee = Employee.find(params[:IDnum].to_i)
    if employee && employee.authenticate(params[:password])
      if employee.status = "Active"
      	log_in employee
    		msg = { :status => "Success", :key => params[:key] }
    		render :json => msg, status: :accepted
      else
        msg = { :status => "ERROR", :message => "App access not granted. Please try again later or contact Human Resources." }
        render :json => msg, status: :forbidden
      end
    else
      msg = { :status => "ERROR", :message => "Invalid ID number and password combination" }
      render :json => msg, status: :forbidden
    end
	end

	# Import Method
	# AUTH app
	def import
		@employees_array = CSV.read("#{Rails.root}/app/assets/TOGV_BUCKS.CSV")
		@employees_array.shift # Get rid of header contents

		@employees_array.each do |e|

			if e[COLUMN_EMPLOYEE_NUMBER] == 'Employee Number'
				return
			end

			if !Job.exists?(jobcode: e[COLUMN_JOB_CODE])
				job_params = { 
					:jobcode => e[COLUMN_JOB_CODE],
					:title => e[COLUMN_JOB_TITLE]
				}
				Job.new(job_params).save
			else
				job = Job.find(e[COLUMN_JOB_CODE])
				if job.title != e[COLUMN_JOB_TITLE]
					job.update_attribute(:title, e[COLUMN_JOB_TITLE])
				end
			end

			if !Department.exists?(name: e[COLUMN_DEPARTMENT])
				Department.new(:name => e[COLUMN_DEPARTMENT],
					:property_id => e[COLUMN_EMPLOYEE_NUMBER][0..-8]).save
			end

			if !Employee.exists?(IDnum: e[COLUMN_EMPLOYEE_NUMBER])
				employee_params = { 
					:IDnum => e[COLUMN_EMPLOYEE_NUMBER],
					:first_name => extract_first_name(e[COLUMN_EMPLOYEE_NAME]),
					:last_name => extract_last_name(e[COLUMN_EMPLOYEE_NAME]),
					:job_id => e[COLUMN_JOB_CODE],
					:department_id => extract_department_id(e[COLUMN_DEPARTMENT]),
					:password => extract_initial_password(e[COLUMN_HIRED]),
					:property_id => e[COLUMN_EMPLOYEE_NUMBER][0..-8],
					:email => e[COLUMN_EMAIL],
					:status => e[COLUMN_STATUS],
					:new_pass => true
				}

				Employee.new(employee_params).save
			else
				@employee = Employee.find(e[COLUMN_EMPLOYEE_NUMBER])
				@employee.update_attributes(status: e[COLUMN_STATUS], department_id: extract_department_id(e[COLUMN_DEPARTMENT]),
					job_id: e[COLUMN_JOB_CODE], email: e[COLUMN_EMAIL], first_name: extract_first_name(e[COLUMN_EMPLOYEE_NAME]), last_name: extract_last_name(e[COLUMN_EMPLOYEE_NAME]))
			end
		end
	end

	def extract_first_name(name)
		if name.last == '.'
			name.split(", ")[1][0..-4].split.map(&:capitalize).join(' ')
		else
			name.split(", ")[1].split.map(&:capitalize).join(' ')
		end
	end

	def extract_last_name(name)
		name.split(",")[0].split.map(&:capitalize).join(' ')
	end

	def extract_department_id(department_name)
		Department.where(name: department_name).first.id
	end

	def extract_initial_password(hired)
		split = hired.split("/")
		split[0] + "/" + split[2]
	end

	def reset_password
	end 

	def reset_send
		if !Employee.find(params[:IDnum]).nil? && !Employee.find(params[:IDnum]).email.blank?
			@employee = Employee.find(params[:IDnum])
			@employee.send_password_reset
			flash[:title] = 'Success'
			flash[:notice] = "A confirmation email has been sent to " + @employee.email + "! Please follow the instructions in the email. Check spam folders as well."
			redirect_to action: :reset_password
		else
			flash[:title] = 'Error'
			flash[:notice] = "Invalid ID or error occured. Please try again or contact Human Resources."
			redirect_to action: :reset_password
		end
	end

	def reset_form
		@employee = Employee.find_by(reset_key: params[:key])
		if @employee.nil?
			flash[:title] = 'Error'
			flash[:notice] = 'Invalid Reset Key. Enter IDnum and try again'
			redirect_to action: :reset_password
		end
	end


	def reset_perform
		@employee = Employee.find_by(reset_key: params[:change][:key])

	  requirements = /[A-Za-z0-9!@#$%^&*]{6,12}/

	  if !@employee.nil?
			if (params[:change][:new1] == params[:change][:new2])
				if requirements.match(params[:change][:new1])
					@employee.update_attributes(password: params[:change][:new1], reset_key: nil, reset_key_time: Time.now)
					flash[:title] = 'Success'
					flash[:notice] = 'Password changed.'
					redirect_to controller: :employees, action: :reset_complete
				else
					flash[:title] = 'Error'
					flash[:notice] = 'Password does not meet the specified requirements.'
					redirect_to action: :reset_form, key: params[:key]
				end
			else
				flash[:title] = 'Error'
				flash[:notice] = 'Passwords must match.'
				redirect_to action: :reset_form, key: params[:key]
			end
		else
			flash[:title] = 'Error'
			flash[:notice] = 'Invalid Reset Key'
			redirect_to action: :reset_password
		end
	end

	private
  def create_params
    params.require(:employee).permit(:IDnum, :password)
  end

end