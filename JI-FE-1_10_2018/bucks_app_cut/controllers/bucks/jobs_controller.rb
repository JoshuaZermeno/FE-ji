module Bucks
	class JobsController < Bucks::ApplicationController
		include SessionsHelper

		before_filter :authenticate_user_logged_in

		def assign_permissions
			if @current_user.has_admin_access
				@permitted = ::Job.where('jobs.' + params[:permission] + ' = 1').pluck(:jobcode)
				@jobs_all = ::Job.joins(:employees).where('employees.property_id = ?', session[:property]).group(:jobcode).order(:title)
			else 
				flash[:title] = 'Error'
				flash[:notice] = 'You do not have permission to edit roles.'
				redirect_to controller: :employees, action: 'show', id: @current_user.id
			end
		end

		def edit
			if @current_user.has_admin_access
				::Job.find(params[:jobcode]).update_attribute(params[:permission], params[:flag])
				redirect_to action: 'assign_permissions', permission: params[:permission]
			end
		end

		def import
			@jobs_imported = CSV.read("#{Rails.root}/public/jobs_import.csv")
			::Job.delete_all
			@jobs_imported.shift # Get rid of header contents
			@jobs_imported.each do |j|
				if !::Job.exists?(jobcode: j[0])
					job_params = { 
						:jobcode => j[0],
						:title => j[1]
					}
					::Job.new(job_params).save
				end
			end
			redirect_to action: 'index'
		end

		def index
			@jobs = Job.all
		end

		def permissions
			if @current_user.has_admin_access
				@jobs_unassigned = ::Job.joins(:employees).where(bucks_earn: false, bucks_issue: false).where('employees.property_id = ?', session[:property]).group(:jobcode).order(:title)
			else 
				flash[:title] = 'Error'
				flash[:notice] = 'You do not have permission to view roles.'
				redirect_to controller: :employees, action: 'show', id: @current_user.id
			end
		end

	end
end