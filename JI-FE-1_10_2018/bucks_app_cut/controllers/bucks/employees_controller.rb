module Bucks
  class EmployeesController < Bucks::ApplicationController
		helper Bucks::BucksHelper

  	before_filter :authenticate_user_logged_in

		def analyze
			if @current_user.has_admin_access || (@current_user.is_same_department(::Employee.find(params[:id])) && @current_user.can_issue_bucks)
				@employee = ::Employee.find(params[:id])
				@buckets = Bucket.where(property_id: session[:property]).order(:name)
				@months = Buck.group("month(bucks_bucks.approved_at)").where(issuer_id: @employee.IDnum).map { |b| b.approved_at.strftime("%B") if !b.approved_at.nil? } 
				@years = Buck.group("year(bucks_bucks.approved_at)").where(issuer_id: @employee.IDnum).map { |b| b.approved_at.strftime("%Y") if !b.approved_at.nil? }
				@department = ::Department.find(@employee.department_id)
				@department_budget = @department.get_budget_overall
				@budget_per_employee = @department.get_budget_per_employee
				if params[:month].blank?
					@month = Time.now.strftime("%B") 
				else
					@month = params[:month] 
				end
				if params[:year].blank?
					@year = Time.now.strftime("%Y")
				else
					@year = params[:year]
				end
				@bucks = Buck.search_employee(@employee.IDnum, @month, @year)
				@bucks_by_day = @bucks.group('DATE(created_at)').count
			else 
				flash[:title] = 'Error'
				flash[:notice] = 'You do not have permission to view analytics of that employee. Must be of same department or have administrator access.'
				redirect_to controller: :employees, action: :show, id: @current_user.IDnum
			end
		end

  	def home
			@featured = Prize.where(available: true, featured: true, property_id: session[:property]).group(:name)
			@buckets = Bucket.where(property_id: session[:property], rankings: true).order(:name )

			@rankings = Hash.new
	    @buckets.each do |b|
	    	results = ::Employee.select("employees.id, employees.IDnum, count(bucks_bucks.id) AS bucks_count").
	    	joins(:bucks).
	    	where("bucks_bucks.bucket_id = ? AND bucks_bucks.status <> 'Void' AND employees.status <> 'Terminated'", b.id).
	    	group("employees.IDnum").
	    	order("bucks_count DESC").
	    	limit(5)
	    	@rankings.store( b.name, results)
	    end

			# @top_aplus = Employee.top_aplus
			# @top_attendance = Employee.top_attendance
			# @top_community = Employee.top_community
			# @top_initiative = Employee.top_initiative
			# @top_service = Employee.top_service
			# @top_shift = Employee.top_shift
			# @top_other = Employee.top_other
			@slide_images = SlideImage.where(property_id: session[:property])
		end
		
	def index
		if @current_user.has_admin_access || @current_user.can_view_all
			@employees = ::Employee.search_all(params[:search_id], params[:search_first_name], params[:search_last_name]).where(property_id: session[:property]).first(40)
			@month_i = Time.now.month
			@year = Time.now.year
		else
			flash.now[:title] = 'Error'
			flash.now[:notice] = 'You do not have permission to view those employees.'
			render 'index'
		end
	end

		def show
			@employee = ::Employee.find(params[:id])
			if @current_user.can_view_employee(@employee) || @employee.IDnum == @current_user.IDnum
				@bucks = Buck.where(employee_id: @employee.IDnum)
				@bucks_nonvoid = Buck.where(employee_id: @employee.IDnum).where(status: ['Active','Partial','Redeemed'])		
				@purchases = Purchase.where(employee_id: @employee.IDnum).where(returned: false)
				@buckets = Bucket.where(property_id: session[:property], rankings: true).order(:name)
				@job = ::Job.find(@employee.job_id)
			else
				flash[:title] = 'Error'
				flash[:notice] = 'You do not have permission to view that employee.'
				redirect_to action: :show, id: @current_user.IDnum
			end
		end

		def team
			if @current_user.can_view_dept
				@employees = ::Employee.where(department_id: @current_user.department_id).search_preshow(params[:search_id], params[:search_first_name], params[:search_last_name]).order(:last_name)
				@months = Buck.group("month(bucks_bucks.approved_at)").map { |b| b.approved_at.strftime("%B") if !b.approved_at.nil? } 
				@years = Buck.group("year(bucks_bucks.approved_at)").map { |b| b.approved_at.strftime("%Y") if !b.approved_at.nil? }
				@department = ::Department.find(@current_user.department_id)
				@buckets = Bucket.where(property_id: session[:property]).order(:name)

				# FUTURE: Properly utilize Buck.model methods to get buck sets like it is used for admin reporting.
				# Adapt based on params, always show something even without a filter.
				if !params[:month].blank? && !params[:year].blank?
					@month = params[:month] if !params[:month].blank?
					@month_i = Date::MONTHNAMES.index(@month)
					@year = params[:year] if !params[:year].blank?
					@department_budget = @department.get_budget_overall
					@budget_per_employee = @department.get_budget_per_employee

					@bucks_month = Buck.get_from_month(params[:month], params[:year])
					@bucks_issued = @bucks_month.joins('INNER JOIN employees ON bucks_bucks.issuer_id = employees.IDnum').where('employees.department_id = ' + @current_user.department_id.to_s)
					@issuers = ::Employee.joins('INNER JOIN bucks_bucks ON bucks_bucks.issuer_id = employees.IDnum')
	    				.where('extract(year from bucks_bucks.approved_at) = ?
	        			AND extract(month from bucks_bucks.approved_at) = ?', "#{@year}", "#{@month_i}")
	      				.where('bucks_bucks.status <> "Void" AND employees.department_id = ?', "#{@department.id}").group(:IDnum)
					
					@bucks_earned = @bucks_month.joins('INNER JOIN employees ON bucks_bucks.employee_id = employees.IDnum').where('employees.department_id = ' + @current_user.department_id.to_s)
					@earners = ::Employee.joins('INNER JOIN bucks_bucks ON bucks_bucks.issuer_id = employees.IDnum')
					.where('extract(year from bucks_bucks.approved_at) = ?
	        			AND extract(month from bucks_bucks.approved_at) = ?', "#{@year}", "#{@month_i}")
	      				.where('bucks_bucks.status <> "Void" AND employees.department_id = ?', "#{@department.id}").group(:IDnum)
				else
					@month_i = Time.now.month
					@year = Time.now.year
				end
			else
				flash.now[:title] = 'Error'
				flash.now[:notice] = 'You do not have permission to view an entire department.'
				render 'index'
			end
		end

  end
end
