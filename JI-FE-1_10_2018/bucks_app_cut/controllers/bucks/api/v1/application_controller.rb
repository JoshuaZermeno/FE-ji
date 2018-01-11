module Bucks
	class Bucks::Api::V1::ApplicationController < ::ApplicationController
		protect_from_forgery with: :null_session

		before_action :destroy_session

		def destroy_session
			request.session_options[:skip] = true
		end

	end
end