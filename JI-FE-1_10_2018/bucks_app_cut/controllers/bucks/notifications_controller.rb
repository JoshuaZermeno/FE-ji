module Bucks
	class NotificationsController < Bucks::ApplicationController
		include EmployeesHelper
		include SessionsHelper

		before_filter :authenticate_user_logged_in

		def index
			if params[:notification_id]
				Notification.where(id: params[:notification_id]).update_all(read: true)
			end
			@notifications = Notification.where(to_id: @current_user.IDnum).order(created_at: :desc, read: :desc)
			@notifications_read = @notifications.where(read: true)
			@notifications_unread = @notifications.where(read: false)
		end

		def mark_as_read
			Notification.where(id: params[:notification_ids]).update_all(read: true)
			flash[:title] = 'Success'
			flash[:notice] = 'Notifications marked as read.'
			redirect_to action: :index
		end

		def mark_all_as_read
			Notification.all.update_all(read: true)
			flash[:title] = 'Error'
			flash[:notice] = 'All notifications marked as read.'
			redirect_to action: :index
		end
	end
end