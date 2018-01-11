require 'transaction_methods'

module Bucks
	class PurchasesController < Bucks::ApplicationController
		include ApplicationHelper
		include BucksHelper
		include SessionsHelper
		include TransactionMethods

		before_filter :authenticate_user_logged_in

		def complete
			@employee = ::Employee.find(params[:employee][:id])

			if params[:prize][:id] != ''
				@prize = Prize.find(params[:prize][:id])
				@inventory = Inventory.find(params[:prize][:inventory_id])
				quantity = params[:prize][:quantity].to_i
				date = params[:prize][:date_of_use]
				price = @inventory.price.to_s.delete('$').to_i
				valid_purchase = true
				
				if @employee.status != "Active"
					@prize.errors.add(:employee, "Employee is Terminated and ineligible to make purchases.")
					valid_purchase = false
				end

				if @employee.get_bucks_balance < ( price * quantity )
					@prize.errors.add(:price, "You do not have enough bucks.")
					valid_purchase = false
				end

				if @prize.property_id != @current_user.property_id
					@prize.errors.add(:employee, "You cannot purchase prizes available at other properties.")
					valid_purchase = false
				end

				if !@prize.must_order
					if quantity > @inventory.stock
						@prize.errors.add(:quantity, "Not enough in stock to purchase that quantity.")
						valid_purchase = false
					end
				end

				if (@prize.request_date && (date.blank? || date == "Select Date")) && params[:online]
					@prize.errors.add(:request_date, "You must enter date that you wish to use or receive the item.")
					valid_purchase = false
				end

				if !@prize.limit.nil?
					if quantity > @prize.limit
						@prize.errors.add(:limit, "Prize is limited to " + @prize.limit.to_s + " per person.")
						valid_purchase = false
					end

					if quantity + @employee.purchase_count(@prize) > @prize.limit
						@prize.errors.add(:limit, "Prize is limited to " + @prize.limit.to_s + " per person. Employee has previous purchases which would cause them to exceed their limit")
						valid_purchase = false
					end
				end

				if !@inventory.limit.nil?
					if quantity > @inventory.limit
						@prize.errors.add(:limit, "That specific prize is limited to " + @prize.limit.to_s + " per person.")
						valid_purchase = false
					end

					if quantity + @employee.purchase_count(@inventory) > @inventory.limit
						@prize.errors.add(:limit, "That specific prize is limited to " + @inventory.limit.to_s + " per person. Employee has previous purchases which would cause them to exceed their limit")
						valid_purchase = false
					end
				end

				if valid_purchase
					if params[:online]
							quantity.times do
								purchase = request_order(@prize, @inventory, @employee, @current_user)
								perform_bucks_purchase_transaction(@prize, purchase, @employee, @current_user, "Web Store")
							end
							Mailer.order_notify(@prize, @inventory, @employee, quantity, date).deliver_now
							flash[:title] = 'Success'
							flash[:notice] = 'Item is reserved! Once the order has been processed, 
							you can find the prize in your wardrobe bag or pick it up from wardrobe during open hours. If it is a large item, you will be able to pick it up at security.'
							redirect_to controller: :purchases, action: :orders_personal
					else
						if @current_user.can_manage_inventory && !@prize.must_order
							quantity.times do
								purchase = makePurchase(@prize, @inventory, @employee, @current_user)
								perform_bucks_purchase_transaction(@prize, purchase, @employee, @current_user, "In Store")
							end
							if params[:commit] == 'Confirm'
								flash[:title] = 'Success'
								flash[:notice] = 'Purchase confirmed and complete.'
								redirect_to employee_path(@employee)
							else
								flash[:title] = 'Success'
								flash[:notice] = 'Purchase confirmed. Continue purchases for ' + @employee.full_name
								redirect_to controller: :purchases, action: :finish, id: params[:employee][:id]
							end
						else
							quantity.times do
								purchase = request_order(@prize, @inventory, @employee, @current_user)
								perform_bucks_purchase_transaction(@prize, purchase, @employee, @current_user, "In Store")
							end
							Mailer.order_notify(@prize, @inventory, @employee, quantity, params[:date]).deliver_now
							flash[:title] = 'Success'
							flash[:notice] = 'Item is reserved, but must be ordered by HR.'
							redirect_to controller: :purchases, action: :orders_personal
						end
					end
				else
					flash[:title] = 'Error'
					flash[:notice] = @prize.errors.messages
					if params[:online]
						redirect_to controller: :prizes, action: :show, id: @prize.id
					else
						redirect_to controller: :purchases, action: :finish, id: @employee.IDnum
					end
				end
			end
		end

		def confirm
			@purchase = Purchase.find(params[:id])
			@purchase.update_attributes(pickedup_by: nil, status: 'Purchased')
			StoreLog.new(:employee_id => @purchase.employee_id, 
				:cashier_id => @current_user.id, 
				:prize_id => @purchase.prize_id,
				:purchase_id => @purchase.id,
				:trans => "Delivered").save

			notification_params = { to_id: @purchase.employee_id, 
				from_id: @current_user.IDnum,
				target_id: @purchase.prize_id, 
				category: Notification::ORDER_COMPLETE }
			@notification = Notification.new(notification_params)
			@notification.save

			@push_receiver = ::Employee.find(@notification.to_id)
			if !@push_receiver.fcm_token.nil?
				fcm = FCM.new(Rails.application.secrets.fcm_key)
				push_fcm_tokens = Array.new
				push_fcm_tokens.push(@push_receiver.fcm_token)
				options = {data: {action: @notification.get_category, text: @notification.get_message}}
				fcm_response = fcm.send(push_fcm_tokens, options)
			end

			flash[:title] = 'Success'
			flash[:notice] = 'Purchase order confirmed and delivered.'
			redirect_to controller: :purchases, action: :orders
		end

		def drop
			Purchase.find(params[:id]).update_attributes(pickedup_by: nil)
			redirect_to action: 'orders'
		end

		def finish
			if @current_user.can_manage_inventory
				@employee = ::Employee.find(params[:id])
				if @employee.property_id.to_i == session[:property].to_i
					@inventories = Inventory.joins(:prize).where('bucks_prizes.property_id = ?', session[:property]).cashier_search(params[:name], params[:size], params[:color], params[:brand], params[:available]).order("bucks_prizes.#{sort_prize_column} #{sort_prize_direction}")
				else
					flash[:title] = 'Error'
					flash[:notice] = 'You do not have permission to authorize a transaction for an employee from a different property than your own.'
					redirect_to controller: :employees, action: :show, id: @current_user.IDnum
				end
			else
				flash[:title] = 'Error'
				flash[:notice] = 'You do not have permission to manage store transactions.'
				redirect_to controller: :employees, action: :home
			end
		end

		def manage
			if @current_user.can_manage_inventory
				@purchases = Purchase.order(created_at: :desc).joins('INNER JOIN employees ON employees.IDnum = bucks_purchases.employee_id').search(params[:search_id], params[:search_first_name], params[:search_last_name], params[:search_date])
			else
				flash[:title] = 'Error'
				flash[:notice] = 'You do not have permission to manage purchases.'
				redirect_to controller: :employee, action: :home
			end
		end

		def orders
			if @current_user.can_manage_inventory
				@orders = Purchase.joins('INNER JOIN employees ON employees.IDnum = bucks_purchases.employee_id').where('employees.property_id = ?', session[:property]).where(status: 'Ordered', pickedup_by: nil)
				@orders_picked_up = Purchase.joins('INNER JOIN employees ON employees.IDnum = bucks_purchases.employee_id').where('employees.property_id = ?', session[:property]).where(status: 'Ordered', pickedup_by: @current_user.id)
				@orders_picked_up_others = Purchase.joins('INNER JOIN employees ON employees.IDnum = bucks_purchases.employee_id').where('employees.property_id = ?', session[:property]).where(status: 'Ordered').where.not(pickedup_by: @current_user.id).where.not(pickedup_by: nil)
			else
				flash[:title] = 'Error'
				flash[:notice] = 'You do not have permission to view any orders except your own.'
				redirect_to controller: :purchases, action: :orders_personal
			end
		end

		def orders_personal
			@orders = Purchase.where(status: ['Ordered', 'Reserved']).where(employee_id: @current_user.id)
		end

		def pickup
			Purchase.find(params[:id]).update_attribute(:pickedup_by, @current_user.id)
			redirect_to action: 'orders'
		end
		
		def refund
			@purchase = Purchase.find(params[:purchase_id])

			@prize = Prize.find(@purchase.prize_id)
			@total_refund = 0
			@bucks_used = BuckLog.where(purchase_id: params[:purchase_id], event: "Spent")

			@bucks_used.each do |b|
				buck = Buck.find(b.buck_id)
				refund = b.value_before - b.value_after
				buck.update_attributes(value: (buck.value + refund), status: b.status_before)
				BuckLog.new(:buck_id => buck.id, 
						:event => 'Refunded', 
						:performed_id => @current_user.id,
						:received_id => buck.employee_id,
						:value_before => b.value_after,
						:value_after => b.value_before,
						:status_before => b.status_after,
						:status_after => b.status_before,
						:purchase_id => @purchase.id).save
				@total_refund = @total_refund + refund
			end

			inventory = Inventory.find(params[:inventory_id])
			inventory.update_attribute(:stock, inventory.stock + 1) if !@prize.must_order
			@prize.update_availability

			StoreLog.new(:employee_id => @purchase.employee_id, 
				:cashier_id => @current_user.id, 
				:purchase_id => @purchase.id,
				:prize_id => params[:prize_id],
				:inventory_id => params[:inventory],
				:trans => "Returned").save

			@notification = Notification.new(:to_id => @purchase.employee_id, 
				:from_id => @current_user.id, 
				:target_id => inventory.prize_id,
				:category => Notification::REFUND_PRIZE)
			@notification.save

			@push_receiver = ::Employee.find(@notification.to_id)
			if !@push_receiver.fcm_token.nil?
				fcm = FCM.new(Rails.application.secrets.fcm_key)
				push_fcm_tokens = Array.new
				push_fcm_tokens.push(@push_receiver.fcm_token)
				options = {data: {action: @notification.get_category, text: @notification.get_message}}
				fcm_response = fcm.send(push_fcm_tokens, options)
			end

			@purchase.update_attribute(:returned, true)
			@purchase.update_attribute(:status, "Returned")
			flash[:title] = 'Success'
			flash[:notice] = 'Employee has been refunded $' + @total_refund.to_s
			redirect_to action: :manage
		end

		def reserve(prize, inventory, employee)
			if inventory.stock > 0
				stock_before = inventory.stock
				inventory.update_attribute(:stock, inventory.stock - 1)
				prize.update_availability
				purchase = Purchase.new(:prize_id => prize.id,
						:inventory_id => inventory.id,
						:employee_id => employee.id,
						:cashier_id => @current_user.id,
						:status => "Reserved")
				purchase.save

				StoreLog.new(:employee_id => @current_user.id, 
						:cashier_id => @current_user.id, 
						:purchase_id => purchase.id,
						:prize_id => @prize.id,
						:inventory_id => @inventory.id,
						:trans => "Reserved",
						:stock_before => stock_before,
						:stock_after => @inventory.stock).save

				return purchase
			else
					flash[:title] = 'Error'
					flash[:notice] = 'Out of stock.'
					redirect_to action: :show, id: @prize.id
			end
		end

		def reserved
			if @current_user.can_manage_inventory
				@reserved = Purchase.joins('INNER JOIN employees ON employees.IDnum = bucks_purchases.employee_id').where('employees.property_id = ?', session[:property]).where(status: 'Reserved')
			else 
				flash[:title] = 'Error'
				flash[:notice] = 'You do not have permission to manage all reserved items.'
				redirect_to controller: :employee, action: :home
			end
		end

		def sign
			@order = Order.find(params[:order_id])
			@employee = ::Employee.find(params[:employee_id])
			@property_name = ::Property.find(session[:property]).name
			@inventory = Inventory.find(params[:inventory_id]) 
			@size = Size.find(@inventory.size_id)
			@amount = (@order.cost.to_f / Pickup.where(order_id: @order.id).count.to_f).round(2)
		end

		def start_purchase
			if !params[:search_id_swipe].nil?
				if params[:search_id_swipe][0] == "%" || params[:search_id_swipe][0] == ";"
					params[:search_id] = params[:search_id_swipe].scan(/\d/).join('')[0...9]
					redirect_to controller: :purchases, action: :finish, id: params[:search_id]
				end
			end
			
			if @current_user.can_manage_inventory
				@employees = ::Employee.where(property_id: session[:property]).search_all(params[:search_id], params[:search_first_name], params[:search_last_name])	
			else
				flash[:title] = 'Error'
				flash[:notice] = 'You do not have permission to manage store transactions.'
				redirect_to controller: :employee, action: :home
			end
		end

		def start_manage
			if @current_user.can_manage_inventory
				@employees = ::Employee.where(property_id: session[:property]).search_all(params[:search_id], params[:search_first_name], params[:search_last_name])	
			else
				flash[:title] = 'Error'
				flash[:notice] = 'You do not have permission to manage purchases.'
				redirect_to controller: :employee, action: :home
			end
		end

	end
end