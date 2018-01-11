module Bucks
	class Api::V1::EmployeesController < Bucks::Api::V1::BaseController

		rescue_from ActiveRecord::RecordNotFound, with: :not_found

		before_filter :authenticate_user

		def not_found
			return head status: 404
		end

		def check
			@employee = ::Employee.find(params[:id])
			render(json: Api::V1::EmployeeCheckSerializer.new(@employee).to_json)
		end

		# Used for pulling up a list of employees who can receive bucks when attempting
		# to issue a new buck. Only include employees eligible to earn
		def index
			@earners = ::Employee.where(status: 'Active', property_id: params[:property_id]).where('IDnum LIKE ? 
				OR first_name LIKE ? 
				OR last_name LIKE ?', 
				"%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%")
			.order("CASE department_id WHEN '#{params[:dept_id]}' THEN 0 ELSE 1 END").joins('INNER JOIN jobs ON jobs.jobcode = employees.job_id').where('jobs.bucks_earn = 1').group(:IDnum).first(10)
			render json: @earners, each_serializer: Api::V1::EmployeeSimpleSerializer
		end

		def new

		end

		def show
			@employee = ::Employee.find(params[:id])
			render(json: Api::V1::EmployeeSerializer.new(@employee).to_json)
		end
	end
end