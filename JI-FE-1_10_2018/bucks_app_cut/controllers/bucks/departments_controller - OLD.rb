module Bucks
	class DepartmentsController < ApplicationController
		include SessionsHelper
		include BucksHelper
		include EmployeesHelper
		include ApplicationHelper
		include DepartmentsHelper

		before_filter :authenticate_user_logged_in
		
		def approvers
			@dept = ::Department.find(params[:dept])
			if @dept.property_id == session[:property].to_i
				@jobs = ::Job.joins(:employees).where("employees.property_id = ?", session[:property]).group(:jobcode).order(:title)
				@number = params[:number]
			else
				flash[:title] = 'Error'
				flash[:notice] = 'That department is not the right property.'
				redirect_to action: :edit
			end
		end

		def approver_add
			@dept = ::Department.find(params[:dept])
			if !params[:jobcode].nil?
				if params[:number] == '1'
					@dept.update_attribute(:bucks_approve1, params[:jobcode])
				else
					@dept.update_attribute(:bucks_approve2, params[:jobcode])
				end

				@job = ::Job.find_by(jobcode: params[:jobcode])
				flash[:title] = 'Success'
				flash[:notice] = @job.title + ' has been successfully assigned as an approver #' + params[:number] + ' for ' + @dept.name
				redirect_to action: :edit
			else
				if params[:number] == '1'
					@dept.update_attribute(:bucks_approve1, nil)
				else
					@dept.update_attribute(:bucks_approve2, nil)
				end

				flash[:title] = 'Success'
				flash[:notice] = 'Approver #' + params[:number] + ' has been reset'
				redirect_to action: :edit
			end	
		end

		def create
			@department = ::Employee.new(employee_params)
		end

		def edit
			@departments = ::Department.where(property_id: session[:property]).order(name: :asc)
		end

		def reports
			if @current_user.has_admin_access
				@bucks = Buck.all.where.not(status: ["Void", "Denied"]).joins('INNER JOIN employees ON bucks_bucks.issuer_id = employees.IDnum').where("employees.property_id = ?", session[:property])
				@bucks_all = Buck.all.joins('INNER JOIN employees ON bucks_bucks.issuer_id = employees.IDnum').where("employees.property_id = ?", session[:property])
				@bucks_voided = Buck.where(status: "Void").joins('INNER JOIN employees ON bucks_bucks.issuer_id = employees.IDnum').where("employees.property_id = ?", session[:property])
				@purchases = Purchase.joins('INNER JOIN employees ON bucks_purchases.employee_id = employees.IDnum').where("employees.property_id = ?", session[:property])
				@favorites = Favorite.joins('INNER JOIN employees ON bucks_favorites.employee_id = employees.IDnum').where("employees.property_id = ?", session[:property])
				@buckets = Bucket.where(property_id: session[:property]).order(:name)

				@partial_spent = 0
				@bucks.where(status: "Partial").each do |b|
					@partial_spent = @partial_spent + ( b.original_value.to_i - b.value.to_i )
				end

				@bucks_active = @bucks.where("bucks_bucks.status = 'Active' OR bucks_bucks.status = 'Pending' OR bucks_bucks.status = 'Partial'")
				@bucks_inactive = @bucks.where("bucks_bucks.status = 'Inactive'")
				@bucks_redeemed = @bucks.where("bucks_bucks.status = 'Redeemed'")
				@employees = ::Employee.where(property_id: session[:property])
				@receivers = ::Job.joins('INNER JOIN employees ON jobs.jobcode = employees.job_id').where('employees.status = "Active" AND employees.property_id = ?', session[:property]).where(bucks_earn: true).group('employees.IDnum').size.count
				@issuers = ::Job.joins('INNER JOIN employees ON jobs.jobcode = employees.job_id').where('employees.status = "Active" AND employees.property_id = ?', session[:property]).where(bucks_issue: true).group('employees.IDnum').size.count
				@prizes = Prize.where(property_id: session[:property])
				@earners = Buck.joins('INNER JOIN employees ON bucks_bucks.issuer_id = employees.IDnum').where('employees.status = "Active"').group(:employee_id).count.count
				
				@bucks_earned = Buck.all.where.not(status: ["Void", "Denied"]).joins('INNER JOIN employees ON bucks_bucks.employee_id = employees.IDnum').where("employees.property_id = ?", session[:property])
				@top_earners = @bucks_earned.joins('INNER JOIN employees ON bucks_bucks.employee_id = employees.IDnum').select("employees.IDnum, sum(original_value) AS bucks_value").group("employees.IDnum").order("bucks_value DESC").limit(10)
				@top_balances = @bucks_earned.joins('INNER JOIN employees ON bucks_bucks.employee_id = employees.IDnum').where("bucks_bucks.status = 'Active' OR bucks_bucks.status = 'Partial'").select("employees.id, employees.IDnum, sum(value) AS bucks_value").group("employees.IDnum").order("bucks_value DESC").limit(10)
				@top_issuers = @bucks.joins('INNER JOIN employees ON bucks_bucks.issuer_id = employees.IDnum').where("employees.property_id = ?", session[:property]).select("employees.id, employees.IDnum, sum(original_value) AS bucks_value").group("employees.id").order("bucks_value DESC").limit(10)
				
				@bucks_spent = @bucks.sum(:original_value) - @bucks.sum(:value)
				@top_purchased = @purchases.joins(:prize).select("bucks_prizes.id, bucks_prizes.name, count(bucks_purchases.id) AS purchases_count").group("bucks_prizes.id").order("purchases_count DESC").limit(5)
				@top_favorited = @favorites.all.joins(:inventory).select("bucks_inventories.id, bucks_inventories.prize_id, bucks_favorites.inventory_id, count(bucks_favorites.id) AS favorites_count").group("bucks_inventories.id").order("favorites_count DESC").limit(5)
				
				@months = Buck.group("month(bucks_bucks.approved_at)").map { |b| b.approved_at.strftime("%B") if !b.approved_at.nil? } 
				@years = Buck.group("year(bucks_bucks.approved_at)").map { |b| b.approved_at.strftime("%Y") if !b.approved_at.nil? }
				@quarters = [1,2,3,4]
			else 
				flash[:title] = 'Error'
				flash[:notice] = 'You do not have permission to view department reports and statistics.'
				redirect_to controller: :employees, action: :show, id: @current_user.IDnum
			end
		end

		def reports_redirect
			if params[:report_button] == "Show Year Report"
				redirect_to action: :reports_year, year: params[:year]
			elsif params[:report_button] == "Show Month Report"
				redirect_to action: :reports_month, month: params[:month], year: params[:year]
			elsif params[:report_button] == "Show Quarterly Report"
				redirect_to action: :reports_quarter, quarter: params[:quarter], year: params[:year]
			end
		end

		def reports_month
			if @current_user.has_admin_access
				if !params[:month].blank? && !params[:year].blank?
					@month = params[:month] if !params[:month].blank?
					@year = params[:year] if !params[:year].blank?
	 
					@bucks = Buck.get_from_month(@month, @year).joins('INNER JOIN employees ON bucks_bucks.issuer_id = employees.IDnum').where("employees.property_id = ?", session[:property])
					@purchases = Purchase.get_from_month(@month, @year).joins('INNER JOIN employees ON bucks_purchases.employee_id = employees.IDnum').where("employees.property_id = ?", session[:property])
					@favorites = Favorite.get_from_month(@month, @year).joins('INNER JOIN employees ON bucks_favorites.employee_id = employees.IDnum').where("employees.property_id = ?", session[:property])
					@buckets = Bucket.where(property_id: session[:property]).order(:name)
					@partial_spent = 0
					@bucks.where(status: "Partial").each do |b|
						@partial_spent = @partial_spent + ( b.original_value.to_i - b.value.to_i )
					end
					@bucks_active = @bucks.where("bucks_bucks.status = 'Active' OR bucks_bucks.status = 'Pending' OR bucks_bucks.status = 'Partial'")
					@bucks_inactive = @bucks.where("bucks_bucks.status = 'Inactive'")
					@bucks_redeemed = @bucks.where("bucks_bucks.status = 'Redeemed'")
					@floating_bucks = @bucks.joins('INNER JOIN employees ON bucks_bucks.issuer_id = employees.IDnum').where("bucks_bucks.status = 'Active' OR bucks_bucks.status = 'Pending' OR bucks_bucks.status = 'Partial'");
					@floating_bucks_w_inactive = @bucks.joins('INNER JOIN employees ON bucks_bucks.issuer_id = employees.IDnum').where("bucks_bucks.status = 'Active' OR bucks_bucks.status = 'Pending' OR bucks_bucks.status = 'Partial' OR bucks_bucks.status = 'Partial");
					@employees = ::Employee.where(property_id: session[:property])
					@receivers = ::Job.joins('INNER JOIN employees ON jobs.jobcode = employees.job_id').where('employees.status = "Active"').where(bucks_earn: true).group('employees.IDnum').size.count
					@earners = @bucks.group(:employee_id).count.count
					@issuers = ::Job.joins('INNER JOIN employees ON jobs.jobcode = employees.job_id').where('employees.status = "Active"').where(bucks_issue: true).group('employees.IDnum').size.count
					@prizes = Prize.where(property_id: session[:property])

					@top_earners = Buck.get_from_month(@month, @year).joins('INNER JOIN employees ON bucks_bucks.employee_id = employees.IDnum').where("employees.property_id = ?", session[:property]).select("employees.id, employees.IDnum, sum(original_value) AS bucks_value").group("employees.id").order("bucks_value DESC").limit(10)
					@top_issuers = @bucks.select("employees.id, employees.IDnum, sum(original_value) AS bucks_value").group("employees.id").order("bucks_value DESC").limit(10)
					@bucks_spent = @purchases.where(status: "Purchased").joins(:prize).sum(:price)
					@top_purchased = @purchases.joins(:prize).select("bucks_prizes.id, bucks_prizes.name, count(bucks_purchases.id) AS purchases_count").group("bucks_prizes.id").order("purchases_count DESC").limit(5)
					@top_favorited = @favorites.joins(:inventory).select("bucks_inventories.id, bucks_inventories.prize_id, bucks_favorites.inventory_id, count(bucks_favorites.id) AS favorites_count").group("bucks_inventories.id").order("favorites_count DESC").limit(5)

					@departments = ::Department.where(property_id: session[:property]).order(:name)
				end
			else 
				flash[:title] = 'Error'
				flash[:notice] = 'You do not have permission to view department reports.'
				redirect_to controller: :employees, action: :show, id: @current_user.IDnum
			end
		end

		def reports_quarter
			if @current_user.has_admin_access
					@quarter = params[:quarter] if !params[:quarter].blank?
					@year = params[:year] if !params[:year].blank?
	 
					@bucks = Buck.get_from_quarter(@quarter, @year).joins('INNER JOIN employees ON bucks_bucks.issuer_id = employees.IDnum').where("employees.property_id = ?", session[:property])
					@purchases = Purchase.get_from_quarter(@quarter, @year).joins('INNER JOIN employees ON bucks_purchases.employee_id = employees.IDnum').where("employees.property_id = ?", session[:property])
					@favorites = Favorite.get_from_quarter(@quarter, @year).joins('INNER JOIN employees ON bucks_favorites.employee_id = employees.IDnum').where("employees.property_id = ?", session[:property])
					@buckets = Bucket.where(property_id: session[:property]).order(:name)
					@partial_spent = 0
					@bucks.where(status: "Partial").each do |b|
						@partial_spent = @partial_spent + ( b.original_value.to_i - b.value.to_i )
					end
					@bucks_active = @bucks.where("bucks_bucks.status = 'Active' OR bucks_bucks.status = 'Pending' OR bucks_bucks.status = 'Partial'")
					@bucks_inactive = @bucks.where("bucks_bucks.status = 'Inactive'")
					@bucks_redeemed = @bucks.where("bucks_bucks.status = 'Redeemed'")
					@floating_bucks = @bucks.joins('INNER JOIN employees ON bucks_bucks.issuer_id = employees.IDnum').where("bucks_bucks.status = 'Active' OR bucks_bucks.status = 'Pending' OR bucks_bucks.status = 'Partial'");
					@floating_bucks_w_inactive = @bucks.joins('INNER JOIN employees ON bucks_bucks.issuer_id = employees.IDnum').where("bucks_bucks.status = 'Active' OR bucks_bucks.status = 'Pending' OR bucks_bucks.status = 'Partial' OR bucks_bucks.status = 'Partial");
					@employees = ::Employee.where(property_id: session[:property])
					@receivers = ::Job.joins('INNER JOIN employees ON jobs.jobcode = employees.job_id').where('employees.status = "Active"').where(bucks_earn: true).group('employees.IDnum').size.count
					@earners = @bucks.group(:employee_id).count.count
					@issuers = ::Job.joins('INNER JOIN employees ON jobs.jobcode = employees.job_id').where('employees.status = "Active"').where(bucks_issue: true).group('employees.IDnum').size.count
					@prizes = Prize.where(property_id: session[:property])
					@top_earners = Buck.get_from_quarter(@quarter, @year).joins('INNER JOIN employees ON bucks_bucks.employee_id = employees.IDnum').select("employees.id, employees.IDnum, sum(original_value) AS bucks_value").group("employees.id").order("bucks_value DESC").limit(10)
					@top_issuers = @bucks.select("employees.id, employees.IDnum, sum(original_value) AS bucks_value").group("employees.id").order("bucks_value DESC").limit(10)
					@bucks_spent = @purchases.where(status: "Purchased").joins(:prize).sum(:price)
					@top_purchased = @purchases.joins(:prize).select("bucks_prizes.id, bucks_prizes.name, count(bucks_purchases.id) AS purchases_count").group("bucks_prizes.id").order("purchases_count DESC").limit(5)
					@top_favorited = @favorites.joins(:inventory).select("bucks_inventories.id, bucks_inventories.prize_id, bucks_favorites.inventory_id, count(bucks_favorites.id) AS favorites_count").group("bucks_inventories.id").order("favorites_count DESC").limit(5)

					@departments = ::Department.where(property_id: session[:property]).order(:name)
			end
		end

		def reports_year
			if @current_user.has_admin_access
				@departments = ::Department.where(property_id: session[:property]).order(:name)
				if !params[:year].blank?
					@year = params[:year] if !params[:year].blank?
	 
					@bucks = Buck.get_from_year(@year).joins('INNER JOIN employees ON bucks_bucks.issuer_id = employees.IDnum').where("employees.property_id = ?", session[:property])
					@purchases = Purchase.get_from_year(@year).joins('INNER JOIN employees ON bucks_purchases.employee_id = employees.IDnum').where("employees.property_id = ?", session[:property])
					@favorites = Favorite.get_from_year(@year).joins('INNER JOIN employees ON bucks_favorites.employee_id = employees.IDnum').where("employees.property_id = ?", session[:property])
					@buckets = Bucket.where(property_id: session[:property]).order(:name)
					@partial_spent = 0
					@bucks.where(status: "Partial").each do |b|
						@partial_spent = @partial_spent + ( b.original_value.to_i - b.value.to_i )
					end
					@bucks_active = @bucks.where("bucks_bucks.status = 'Active' OR bucks_bucks.status = 'Pending' OR bucks_bucks.status = 'Partial'")
					@bucks_inactive = @bucks.where("bucks_bucks.status = 'Inactive'")
					@bucks_redeemed = @bucks.where("bucks_bucks.status = 'Redeemed'")
					@months = @bucks.group("month(bucks_bucks.approved_at)").map { |b| b.approved_at.strftime("%B") if !b.approved_at.nil? }
					@floating_bucks = @bucks.joins('INNER JOIN employees ON bucks_bucks.issuer_id = employees.IDnum').where("bucks_bucks.status = 'Active' OR bucks_bucks.status = 'Pending' OR bucks_bucks.status = 'Partial'");
					@floating_bucks_w_inactive = @bucks.joins('INNER JOIN employees ON bucks_bucks.issuer_id = employees.IDnum').where("bucks_bucks.status = 'Active' OR bucks_bucks.status = 'Pending' OR bucks_bucks.status = 'Partial' OR bucks_bucks.status = 'Partial");
					@employees = ::Employee.where(property_id: session[:property])
					@receivers = ::Job.joins('INNER JOIN employees ON jobs.jobcode = employees.job_id').where('employees.status = "Active"').where(bucks_earn: true).group('employees.IDnum').size.count
					@earners = @bucks.group(:employee_id).count.count
					@issuers = ::Job.joins('INNER JOIN employees ON jobs.jobcode = employees.job_id').where('employees.status = "Active"').where(bucks_issue: true).group('employees.IDnum').size.count
					@prizes = Prize.where(property_id: session[:property])
					@top_earners = Buck.get_from_year(@year).joins('INNER JOIN employees ON bucks_bucks.employee_id = employees.IDnum').where("employees.property_id = ?", session[:property]).select("employees.id, employees.IDnum, sum(original_value) AS bucks_value").group("employees.id").order("bucks_value DESC").limit(10)
					@top_issuers = @bucks.select("employees.id, employees.IDnum, sum(original_value) AS bucks_value").group("employees.id").order("bucks_value DESC").limit(10)
					@bucks_spent = @purchases.where(status: "Purchased").joins(:prize).sum(:price)
					@top_purchased = @purchases.joins(:prize).select("bucks_prizes.id, bucks_prizes.name, count(bucks_purchases.id) AS purchases_count").group("bucks_prizes.id").order("purchases_count DESC").limit(5)
					@top_favorited = @favorites.joins(:inventory).select("bucks_inventories.id, bucks_inventories.prize_id, bucks_favorites.inventory_id, count(bucks_favorites.id) AS favorites_count").group("bucks_inventories.id").order("favorites_count DESC").limit(5)
				end
			else 
				flash[:title] = 'Error'
				flash[:notice] = 'You do not have permission to view department reports.'
				redirect_to controller: :employees, action: :show, id: @current_user.IDnum
			end
		end

		def update
			department_ids = params.fetch(:department_ids, "department_ids")
			department_values = params.fetch(:department_values, "department_values")
			valid_input = true

			# Linked to whatever order appearing in the edit action. If order is changed
			# in edit, it must change here also. Department order must match.
			@departments = ::Department.where(id: department_ids).order(name: :asc)
			@departments.each_with_index do |d, i|
				if (Integer(department_values.at(i)) rescue false)
					d.update_attribute(:bucks_budget, department_values.at(i))
				else
					valid_input = false
				end
			end

			if valid_input
				flash.now[:title] = 'Success'
				flash.now[:notice] = 'Budgets have been updated'
			else
				flash.now[:title] = 'Error'
				flash.now[:notice] = 'All input fields must contain a number'
			end

			render 'edit'
		end

			private 
			def department_params
				params.require(:department).permit(:department_ids, :department_values)
			end

	end
end