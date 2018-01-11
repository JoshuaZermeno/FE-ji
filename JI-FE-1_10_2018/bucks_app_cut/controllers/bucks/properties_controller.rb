module Bucks
	class PropertiesController < ApplicationController
		include SessionsHelper
		include BucksHelper
		include EmployeesHelper
		include ApplicationHelper


		before_filter :authenticate_user_logged_in, :authenticate_user_is_admin

		def reports
				@months = Buck.group("month(bucks_bucks.approved_at)").map { |b| b.approved_at.strftime("%B") if !b.approved_at.nil? } 
				@years = Buck.group("year(bucks_bucks.approved_at)").map { |b| b.approved_at.strftime("%Y") if !b.approved_at.nil? }
				@quarters = [1,2,3,4]
		end

		def reports_redirect
			if params[:report_button] == "Show Month Report"
				redirect_to action: :reports_month, month: params[:month], year: params[:year]
			end
		end

		def reports_month
			if !params[:month].blank? && !params[:year].blank?
				@month = params[:month] if !params[:month].blank?
				@year = params[:year] if !params[:year].blank?
				builder = Bucks::ReportBuilder.new(month: 6, year: 2017, property: session[:property])
				@test = builder.build_budget_reports
 
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
		end

			private 
			def property_params
				params.require(:property).permit(:name, :code)
			end

	end
end