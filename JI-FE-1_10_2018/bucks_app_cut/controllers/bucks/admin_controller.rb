module Bucks
	class AdminController < Bucks::ApplicationController
		include ApplicationHelper
		include BucksHelper
		include SessionsHelper

		before_filter :authenticate_user_logged_in

		def dept_budgets
			if @current_user.has_admin_access
				@departments = ::Department.all
			else
				flash[:title] = 'Error'
				flash[:notice] = 'Access: permission denied.'
				redirect_to controller: :employees, action: :show, id: @current_user.IDnum
			end
		end

		def edit_dept_budgets
			if @current_user.has_admin_access
				@departments = ::Department.find(params[:department_ids])
				@values = params[:department_values]
				@departments.each do |d|
					d.update_attribute(:value, @values.get(d.id))
				end
				redirect_to 'bucks'
			else
				flash[:title] = 'Error'
				flash[:notice] = 'Access: permission denied.'
				redirect_to controller: :employees, action: :show, id: @current_user.IDnum
			end
			
		end

		def slideshow
			@slide_images = SlideImage.where(property_id: session[:property])
		end

		def slideshow_upload
			@new_image = SlideImage.new(slideshow_image_params)
			@new_image.property_id = session[:property]
			@new_image.featured = false
			@new_image.save
			redirect_to controller: :admin, action: :slideshow
		end

		def slideshow_delete
			SlideImage.find(params[:id]).delete
			redirect_to controller: :admin, action: :slideshow
		end

		def feedback

		end
		def issue

		end

		def feedback_deliver
			if !params[:feedback_message].blank?
				message = params[:feedback_message]
				Bucks::Mailer.mail_feedback(message, @current_user).deliver_now
				flash.now[:title] = 'Success'
				flash.now[:notice] = 'Your message has been received. Thank you.'
				render 'feedback'
			else
				flash.now[:title] = 'Error'
				flash.now[:notice] = 'You must enter a feedback message.'
				render 'feedback'
			end
			
		end

		def issue_deliver
			if params[:issue_message].blank? || params[:issue_url].blank?
				flash.now[:title] = 'Error'
				flash.now[:notice] = 'You must fill out a message and include the URL where you encountered the problem.'
				render 'issue'
			else
				Bucks::Mailer.mail_issue(params[:issue_message], params[:issue_url], @current_user).deliver_now
				flash.now[:title] = 'Success'
				flash.now[:notice] = 'Your message has been received. Thank you.'
				render 'issue'
			end
		end

		def control_panel
			if !@current_user.has_admin_access
				flash[:title] = 'Error'
				flash[:notice] = 'Access: permission denied.'
				redirect_to controller: :employees, action: :show, id: @current_user.IDnum
			end
		end

		def password_reset
			@employee = ::Employee.find(params[:change][:employee_id])
			requirements = /[A-Za-z0-9!@#$%^&*]{6,12}/

			if (params[:change][:new1] == params[:change][:new2])
				if requirements.match(params[:change][:new1])
					@employee.update_attribute(:password, params[:change][:new1])
					@employee.update_attribute(:reset_key_time, Time.now)
					@employee.update_attribute(:new_pass, true)
					flash[:title] = 'Success'
					flash[:notice] = 'Password changed. User will be prompted to change password when they log in.'
					redirect_to action: :control_panel
				else
					flash[:title] = 'Error'
					flash[:notice] = 'Password does not meet the specified requirements.'
					redirect_to action: :control_panel
				end
			else
				flash[:title] = 'Error'
				flash[:notice] = 'Passwords do not match'
				redirect_to action: :control_panel
			end
		end

		def new_super
			@super_users = ::Employee.where(super: true)
		end

		def new_super_update
			@employee = ::Employee.find_by(IDnum: params[:employee][:IDnum])
			if !@employee.nil?
				if params[:super][:password] == Rails.application.secrets.super_user_key
					if params[:commit] == "Grant"
						@employee.update_attribute(:super, true)
					else
						@employee.update_attribute(:super, false)
					end	
					flash[:title] = 'Success'
					flash[:notice] = 'Access modified'
					redirect_to action: :new_super
				else
					flash[:title] = 'Error'
					flash[:notice] = 'Invalid passcode'
					redirect_to action: :new_super
				end
			else
				flash[:title] = 'Error'
				flash[:notice] = 'Invalid ID # or invalid candidate.'
				redirect_to action: :new_super
			end
		end

		def switch_property
			if @current_user.super
				session[:property] = params[:id]
				flash[:title] = 'Success'
				flash[:notice] = 'You are now viewing the bucks program under the property: ' + ::Property.find(params[:id]).name.to_s
				redirect_to :back
			else
				flash[:title] = 'Error'
				flash[:notice] = 'You do not have permission to view other properties.'
				redirect_to controller: :employee, action: :home
			end
		end


		def update
			
		end

		def slideshow_image_params
			params.require(:slide_image).permit(:id, :property_id, :image, :featured)
		end

	end
end