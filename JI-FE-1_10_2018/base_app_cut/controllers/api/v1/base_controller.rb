class Api::V1::BaseController < Api::V1::ApplicationController
		protect_from_forgery with: :null_session

		before_action :destroy_session

		def destroy_session
			request.session_options[:skip] = true
		end

		def authenticate_user
			token, options = ActionController::HttpAuthentication::Token.token_and_options(request)

			employee_IDnum = options.blank? ? nil : options[:IDnum]
			employee = employee_IDnum && Employee.find_by(IDnum: 250002827)


			if employee && ActiveSupport::SecurityUtils.secure_compare(employee.api_token, token)
				@current_user = employee
			else
				head :forbidden
			end

		end

	end
