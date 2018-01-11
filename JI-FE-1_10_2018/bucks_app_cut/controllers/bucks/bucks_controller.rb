module Bucks
	class BucksController < Bucks::ApplicationController
		include ApplicationHelper
		include BucksHelper
		include EmployeesHelper
		include SessionsHelper
		require 'date'

		helper_method :sort_buck_column, :sort_buck_direction
		before_filter :authenticate_user_logged_in

		def analyze
			if @current_user.has_admin_access
				@floating_bucks = Buck.joins(:employee).where("bucks_bucks.status = 'Active' OR bucks_bucks.status = 'Pending' OR bucks_bucks.status = 'Partial'").where("employees.status = 'Active'")
				@total_balances = 0
				::Employee.where(status: "Active", property_id: session[:property]).each { |e| @total_balances = @total_balances + e.get_bucks_balance }
				@departments = ::Department.where(property_id: session[:property])
				@months = Buck.group("month(bucks_bucks.approved_at)").map { |b| b.approved_at.strftime("%B") if !b.approved_at.nil? } 
				@years = Buck.group("year(bucks_bucks.approved_at)").map { |b| b.approved_at.strftime("%Y") if !b.approved_at.nil? }
				@bucks = Buck.where(department_id: params[:department]).get_from_month(params[:month], params[:year])
				@buckets = Bucket.where(property_id: session[:property]).order(:name)
				if !params[:department].blank? && !params[:month].blank? && !params[:year].blank?
					@department = ::Department.find(params[:department])
					if @department.property_id.to_i == session[:property].to_i
						@month = params[:month] if !params[:month].blank?
						@month_i = Date::MONTHNAMES.index(@month)
						@year = params[:year] if !params[:year].blank?
						@budget_per_employee = @department.get_budget_per_employee
						month = Date::MONTHNAMES.index(params[:month])
						@employees = ::Employee.where(property_id: session[:property]).find_by_sql('SELECT `employees`.* FROM `employees` INNER JOIN `bucks_bucks` ON `employees`.`IDnum` = `bucks_bucks`.`issuer_id` 
							WHERE `bucks_bucks`.`department_id` =  ' + params[:department] + ' AND (extract(year  from bucks_bucks.approved_at) = ' + params[:year].to_s + ' 
							AND extract(month from bucks_bucks.approved_at) = ' + month.to_s + ') AND (bucks_bucks.status <> "Void") GROUP BY `employees`.`IDnum` ORDER BY `employees`.`last_name` ASC')

						@bucks_month = Buck.get_from_month(params[:month], params[:year])
						@bucks_issued = @bucks_month.joins('INNER JOIN employees ON bucks_bucks.issuer_id = employees.IDnum').where('employees.department_id = ?', @department.id)
						@issuers = ::Employee.where(property_id: session[:property]).joins('INNER JOIN bucks_bucks ON bucks_bucks.issuer_id = employees.IDnum')
		    				.where('extract(year from bucks_bucks.approved_at) = ?
		        			AND extract(month from bucks_bucks.approved_at) = ?', "#{@year}", "#{@month_i}")
		      			.where('bucks_bucks.status <> "Void" AND employees.department_id = ?', "#{@department.id}").group(:IDnum)
						
						@bucks_earned = @bucks_month.joins('INNER JOIN employees ON bucks_bucks.employee_id = employees.IDnum').where('employees.department_id = ' + @department.id.to_s)
						@earners = ::Employee.where(property_id: session[:property]).joins('INNER JOIN bucks_bucks ON bucks_bucks.employee_id = employees.IDnum').where('extract(year from bucks_bucks.approved_at) = ?
		        			AND extract(month from bucks_bucks.approved_at) = ?', "#{@year}", "#{@month_i}")
		      				.where('bucks_bucks.status <> "Void" AND employees.department_id = ?', "#{@department.id}").group(:IDnum)
					else
						flash[:title] = 'Error'
						flash[:notice] = 'You do not have permission to analyze that department in that property.'
						redirect_to controller: :bucks, action: :analyze
					end
				end
			else 
				flash[:title] = 'Error'
				flash[:notice] = 'You do not have permission to analyze budgets.'
				redirect_to controller: :employees, action: :show, id: @current_user.IDnum
			end
		end

		def approve
			if @current_user.can_view_buck(Buck.find(params[:id])) && @current_user.can_approve_bucks
				@notifcation = Notification.where(to_id: @current_user.IDnum).where(target_id: params[:id]).first
				@notifcation.update_attribute(:read, true) if !@notifcation.nil?
				@buck = Buck.find(params[:id])
			else 
				flash.now[:title] = 'Error'
				flash.now[:notice] = 'You do not have permission to approve that buck.'
				render 'show'
			end
		end

		def create

			@buck = Buck.new(bucks_params)

			valid_buck = true

			# Employee Panel Validation
			# Only accounts in and validates ID number. If number is blank, add error. If not blank, perform server validation.
			
			if @buck.employee_id.nil?
				@buck.errors.add(:employee_id, "Must enter a valid Employee ID")
				valid_buck = false
			else
				@employee = ::Employee.find(@buck.employee_id)
				if @buck.employee_id == @current_user.IDnum
					@buck.errors.add(:reason, "You cannot issue bucks to yourself")
					valid_buck = false
				end
				if !@employee.can_earn_bucks
					@buck.errors.add(:reason, "Employee is unable to earn bucks")
					valid_buck = false
				end
				if @employee.property_id != session[:property]
					@buck.errors.add(:reason, "You cannot issue bucks to employees in other properties.")
					valid_buck = false
				end
			end

			# Buck/Bucket Information Validation
			# If the user has not selected a bucket other than the default value on the selector (default value is "" contrary
			# to the name of the option which is Select Bucket) do not queue for the bucket, just print error. If an option
			# is selected, validate the options based around buck and bucket requirements
			
			if params[:buck][:bucket_name].blank?
				@buck.errors.add(:reason, "Must select a valid buck category for issuing buck")
				valid_buck = false
			else
				@bucket = Bucket.where(name: params[:buck][:bucket_name], property_id: session[:property]).first
				# If the value has a range that must be entered
				if @bucket.value.nil? && @current_user.can_approve_bucks
					if params[:buck][:value].to_i < @bucket.min || params[:buck][:value].to_i > @bucket.max
						@buck.errors.add(:value, "Buck value is outside of range.")
						valid_buck = false
					end
				end
				if @bucket.reason && params[:buck][:reason] == ''
					@buck.errors.add(:reason, "That buck category requires a reason for issuing the buck to the selected employee.")
					valid_buck = false
				end

				if @bucket.date && params[:buck][:performed_at] == ''
					@buck.errors.add(:performed_at, "Buck requires a date to be selected for when Team Member earned buck.")
					valid_buck = false
				end
			end

			if valid_buck
				@bucket = Bucket.where(name: params[:buck][:bucket_name]).first
				@buck.issuer_id = ::Employee.find(session[:id]).id
				@department = ::Department.find(@employee.department_id)
				@buck.bucket_id = @bucket.id
				@buck.department_id = @employee.department_id
				@buck.number = assign_buck_number
				@buck.value = 0 if @buck.value.blank?
				@buck.original_value = params[:buck][:value]
				@buck.performed_at = params[:buck][:performed_at].to_time if @bucket.date

				# If the issuer possesses the ability to approve bucks, it will skip the approval process and immediately go active
				if @buck.needs_approval(@current_user)
					@buck.status = "Pending"
					@buck.save
					Mailer.pending_buck_approval(@current_user, @buck).deliver_now if @department.has_valid_approvers
				else
					@buck.status = "Active"
					@buck.approved_at = Time.now
					@employee = ::Employee.find(@buck.employee_id)
					@buck.save
					Mailer.notify_employee(@buck, @employee).deliver_now if !@employee.email.blank?
				end

				buck_log_params = { :buck_id => @buck.id, 
					:event => 'Issued', 
					:performed_id => @current_user.id,
					:received_id => @employee.id,
					:value_before => @buck.value,
					:value_after => @buck.value,
					:status_before => @buck.status,
					:status_after => @buck.status }
				BuckLog.new(buck_log_params).save

				if !@department.has_valid_approvers
					Mailer.mail_issue("Automatic email sent for issue: Department missing active approver.", "", @current_user)
				end

				flash[:title] = 'Success'
				flash[:notice] = 'Buck has been submitted!'
				redirect_to action: :show, id: @buck.number
				
			else
				flash[:title] = 'Error'
				flash[:notice] = @buck.errors.messages
				redirect_to :action => 'new'
			end
		end

		def delete
			@buck = Buck.find(params[:id])
			@receiver = ::Employee.find(@buck.employee_id)
			flash[:title] = 'Success'
			flash[:notice] = 'Buck ' + params[:id] + ' has been successfully voided!'

			buck_log_params = { :buck_id => @buck.id, 
				:event => 'Voided', 
				:performed_id => @current_user.id,
				:received_id => @receiver.IDnum,
				:value_before => @buck.value,
				:value_after => @buck.value,
				:status_before => @buck.status,
				:status_after => 'Void' }
			BuckLog.new(buck_log_params).save

			@buck.update_attributes(status: 'Void')
			redirect_to :action => 'index'
		end

		def import
			import_bucks
			redirect_to controller: :employees, action: :index
		end
		
		def index
			if @current_user.has_admin_access || @current_user.can_view_all
				if params[:sort] == 'employeeName'
					@bucks = Buck.joins('INNER JOIN departments ON bucks_bucks.department_id = departments.id').where('departments.property_id = ' + session[:property].to_s).search(params[:search_id], params[:search_recipient_id], params[:search_issuer_id]).sort_by(&:get_employee_name)
				else
					@bucks = Buck.joins('INNER JOIN departments ON bucks_bucks.department_id = departments.id').where('departments.property_id = ' + session[:property].to_s).search(params[:search_id], params[:search_recipient_id], params[:search_issuer_id]).order(sort_buck_column + " " + sort_buck_direction)
				end
			else
				flash.now[:title] = 'Error'
				flash.now[:notice] = 'You do not have permission to view all bucks.'
				render 'index'
			end
		end

		def logs
			if @current_user.has_admin_access
				@buck_logs = BuckLog.joins('INNER JOIN employees ON bucks_buck_logs.performed_id = employees.IDnum').where('employees.property_id = ' + session[:property].to_s).search(params[:buck_id], params[:performed_id], params[:received_id], params[:recent])
			else
				flash.now[:title] = 'Error'
				flash.now[:notice] = 'You do not have permission to view these logs.'
				render 'logs'
			end
		end

		def new
			if params[:employee_IDnum].blank? && params[:employee_first].blank? && params[:employee_last].blank?
				if @current_user.can_issue_special_bucks
					@buckets = Bucket.where(property_id: session[:property]).order(:name).to_a.map(&:name)
				else
					@buckets = Bucket.where(special: false, property_id: session[:property]).order(:name).to_a.map(&:name)
				end
				if !params[:bucket_name].nil? 
					@bucket = Bucket.where(name: params[:bucket_name], property_id: session[:property]).first
					if @bucket.nil?
						@bucket_value = 0;
					else
						@bucket_value = @bucket.value
						@date_required = @bucket.date
						@reason_required = @bucket.reason
						@approval_required = @bucket.approval
					end
				end
			else
				@employees = ::Employee.where(status: 'Active', property_id: session[:property]).search_all(params[:employee_IDnum], params[:employee_first], params[:employee_last]).first(20)
				if @current_user.can_issue_special_bucks
					@buckets = Bucket.where(property_id: session[:property]).order(:name).to_a.map(&:name)
				else
					@buckets = Bucket.where(special: false, property_id: session[:property]).order(:name).to_a.map(&:name)
				end
				if !params[:bucket_name].nil? 
					@bucket = Bucket.where(name: params[:bucket_name], property_id: session[:property]).first
					if @bucket.nil?
						@bucket_value = 0
					else
						@bucket_value = @bucket.value
						@date_required = @bucket.date
						@reason_required = @bucket.reason
						@approval_required = @bucket.approval
					end
				end
			end
		end

		def pending
			if @current_user.can_approve_bucks
				@bucks = @current_user.get_pending_bucks
			else
				flash.now[:title] = 'Error'
				flash.now[:notice] = 'You do not have permission to approve bucks.'
				render 'pending'
			end
		end

		def show
			if @current_user.can_view_buck(Buck.find(params[:id]))
				if Buck.find(params[:id]).employee_id == @current_user.IDnum
					Notification.where(to: @current_user.IDnum).where(target_id: params[:id]).where(category: Notification::NEW_BUCK).first.update_attribute(:read, true)
				else
					Notification.where(to: @current_user.IDnum).where(target_id: params[:id]).each { |n| n.update_attribute(:read, true) if !n.nil? }
				end
				@buck = Buck.find(params[:id])
			else 
				flash[:title] = 'Error'
				flash[:notice] = 'You do not have permission to view that buck.'
				redirect_to controller: :employees, action: :show, id: @current_user
			end
		end

		def update
			@buck = Buck.find(params[:id])
			@bucket = Bucket.find(@buck.bucket_id)

			buck_log_params = { :buck_id => @buck.id,  
				:performed_id => @current_user.id,
				:received_id => @buck.employee_id,
				:value_before => @buck.value,
				:status_before => @buck.status }
			
			if (@current_user.can_approve_bucks || @current_user.has_admin_access) && session[:property] == ::Employee.find(@buck.employee_id).property_id
				if params[:decision] == 'Approve'
					if params[:buck][:value].to_i > @bucket.max && !@current_user.can_issue_special_bucks
						flash[:title] = 'Error'
						flash[:notice] = "You do not have permision to approve more than a value of " + @bucket.max.to_s + " bucks for this buck."
						redirect_to controller: :bucks, action: :approve, id: params[:id]
					else
						@buck.update_attribute(:status, 'Active')
						@buck.update_attribute(:approved_at, Time.now)
						@buck.update_attribute(:value, params[:buck][:value])
						@buck.update_attribute(:original_value, params[:buck][:value])

						buck_log_params[:value_after] = params[:buck][:value]
						buck_log_params[:event] = 'Approved'
						buck_log_params[:status_after] = 'Approved'

						flash[:title] = 'Success'
						flash[:notice] = 'Buck has been approved'
						BuckLog.new(buck_log_params).save

						approved_buck_log_params = { :buck_id => @buck.id,  
							:performed_id => @buck.issuer_id,
							:received_id => @buck.employee_id,
							:event => 'Activated',
							:value_before => @buck.value,
							:value_after => params[:buck][:value],
							:status_before => 'Pending',
							:status_after => 'Active' }
						BuckLog.new(approved_buck_log_params).save

						Mailer.notify_employee(@buck, ::Employee.find(@buck.employee_id)).deliver_now if !::Employee.find(@buck.employee_id).email.blank?
						Mailer.notify_issuer(@buck, ::Employee.find(@buck.issuer_id), ::Employee.find(@buck.employee_id), @current_user, "Approved", "Approved").deliver_now
						
						redirect_to @buck
					end
				elsif params[:decision] == 'Deny'
					@buck.update_attribute(:status, 'Denied')
					@buck.update_attribute(:value, 0)
					buck_log_params[:value_after] = 0
					buck_log_params[:event] = 'Denied'
					buck_log_params[:status_after] = 'Void'

					flash[:title] = 'Error'
					flash[:notice] = 'Buck has been denied'
					BuckLog.new(buck_log_params).save

					Mailer.notify_issuer(@buck, ::Employee.find(@buck.issuer_id), ::Employee.find(@buck.employee_id), @current_user, "Denied", params[:buck][:denial_reason]).deliver_now

					redirect_to @buck
				else
					flash.now[:title] = 'Error'
					flash.now[:notice] = 'Errors'
					render 'approve'
				end
			else
				flash[:title] = 'Error'
				flash[:notice] = 'You do not have permission to approve bucks'
				redirect_to :action => 'index'
			end
		end

		private 
		def bucks_params
			params.require(:buck).permit(:value, :bucket_id, :reason, :prize_id, :decision, :employee_id)
		end

		def makePurchase(prize, employee, item)
			perform_bucks_purchase_transaction(prize, employee)
			item.update_attribute(:status, 'Purchased')

			store_log_params = { :employee_id => employee.id, 
					:cashier_id => @current_user.id, 
					:prize_id => prize.id,
					:item_barcode => item.barcode,
					:trans => "Purchased",
					:balance_before => balance_before,
					:balance_after => employee.get_bucks_balance }

			StoreLog.new(store_log_params).save
		end

		def request_order(prize, employee)
			perform_bucks_purchase_transaction(prize, employee)
			@item = Item.new(name: prize.name, prize_id: prize.id, status: "Ordered")
			@item.save

			store_log_params = { :employee_id => employee.id, 
					:cashier_id => @current_user.id, 
					:prize_id => prize.id,
					:trans => "Ordered",
					:item_id => @item.id,
					:balance_before => employee.get_bucks_balance,
					:balance_after => employee.get_bucks_balance 
				}
			StoreLog.new(store_log_params).save
		end

		def perform_bucks_purchase_transaction(prize, employee)
			balance_before = employee.get_bucks_balance
			spent = 0

			while spent < prize.cost
				@oldest_buck = Buck.where(status: ['Active', 'Partial']).where(employee_id: @employee.id).order(:approved_at).first
				spent = spent + @oldest_buck.value

				buck_log_params = { :buck_id => @oldest_buck.id, 
					:event => 'Spent', 
					:performed_id => @current_user.id,
					:received_id => employee.id,
					:value_before => @oldest_buck.value,
					:status_before => @oldest_buck.status,
					:purchased => prize.id }

				if spent > prize.cost
					@oldest_buck.update_attribute(:value, (spent - prize.cost))
					@oldest_buck.update_attribute(:status, 'Partial')

					buck_log_params[:value_after] = spent - prize.cost
					buck_log_params[:status_after] = 'Partial'
				else
					@oldest_buck.update_attribute(:status, 'Redeemed')
					buck_log_params[:status_after] = 'Redeemed'
					buck_log_params[:value_after] = 0
				end

				BuckLog.new(buck_log_params).save
			end
		end

	end
end