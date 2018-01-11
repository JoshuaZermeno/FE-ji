module Bucks
	class Api::V1::NotificationsController < Bucks::Api::V1::BaseController

		rescue_from ActiveRecord::RecordNotFound, with: :not_found

		before_filter :authenticate_user

	  def not_found
	    return head status: 404
	  end

		def index
			@notifications = Notification.where(to_id: params[:id]).order(created_at: :desc).order(read: :asc).first(20)
			render json: @notifications, each_serializer: Api::V1::NotificationSerializer
		end

		def update
			# Should only be used to update notifications as read. Marking notifications as
			# unread should not be an option.
			@notification = Notification.find(params[:id])
			if !@notification.nil? && !@notification.read
				@notification.update_attribute(:read, true)
				msg = { :status => "Success", :message => "Notification read" }
	      		render json: msg.to_json, status: 201
			else
				msg = { :status => "Error", :message => "Error" }
	      		render json: msg.to_json, status: 409
			end
		end

	end
end