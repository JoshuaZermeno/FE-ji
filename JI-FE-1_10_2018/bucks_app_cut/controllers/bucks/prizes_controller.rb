module Bucks
	class PrizesController < Bucks::ApplicationController
		include ApplicationHelper
		include SessionsHelper
		include PrizesHelper

		before_filter :authenticate_user_logged_in

		def create
			@prize = Prize.new(prize_params)
			if @current_user.can_manage_inventory
				@prize.property_id = session[:property]
				if @prize.save
					flash[:title] = 'Success'
					flash[:notice] = 'Prize has been created. Begin adding inventory for prize.'
					StoreLog.new(:employee_id => @current_user.id, 
						:cashier_id => @current_user.id, 
						:prize_id => @prize.id,
						:trans => 'Created').save
					redirect_to controller: :inventories, action: :manage, id: @prize.id
				else
					flash.now[:title] = 'Error'
					flash.now[:notice] = @prize.errors.messages
					render 'new'
				end
			else
				flash[:title] = 'Error'
				flash[:notice] = 'You do not have permission to edit items'
				redirect_to :action => 'index'
			end
		end

		def discontinue
			if @current_user.can_manage_inventory
				@prize = Prize.find(params[:id])
				stock_before = @prize.get_total_stock
				@prize.update_attributes(available: false)
				flash[:title] = 'Success'
				flash[:notice] = @prize.name + ' has been successfully discontinued from the shop!'
				StoreLog.new(:employee_id => @current_user.id, 
					:cashier_id => @current_user.id, 
					:prize_id => @prize.id,
					:trans => 'Discontinued',
					:stock_before => stock_before,
					:stock_after => 0).save
				redirect_to action: :manage
			else 
				flash[:title] = 'Error'
				flash[:notice] = 'You do not have permission to discontinue that item'
				redirect_to action: :index
			end
		end

		def destroy
			@prize = Prize.find(params[:id])
			if Purchase.where(prize_id: @prize.id).blank?
				@prize.purchases.destroy_all
				@prize.inventories.destroy_all
				@prize.store_logs.destroy_all
				@prize.favorites.destroy_all
				@prize.destroy
				flash[:title] = 'Success'
				flash[:notice] = 'Prize and all related stock, logs, and favorites have been deleted.'
				redirect_to controller: :prizes, action: :manage
			else
				flash[:title] = 'Error'
				flash[:notice] = { 'Errors' => ['Item has related purchases and cannot be deleted.']}
				redirect_to controller: :prizes, action: :edit, id: @prize.id
			end
		end

		def edit
			@prize = Prize.find(params[:id])
		end

		def index
			@subcat_search_result = Inventory.search_store(params[:size], params[:color])
			@subcat_search_result_ids = Array.new
			@subcat_search_result.each { |p| @subcat_search_result_ids.push(p.prize_id) }
			@subcat_search_result_ids.uniq!
			@prizes = Prize.where(id: @subcat_search_result_ids, property_id: session[:property], available: true, in_store_only: false)
			@prizes = @prizes.search_store(params[:name], params[:category], params[:balance]).order(:name)
			@featured = Prize.where(available: true, featured: true, property_id: session[:property]).group(:name)
			@filters = params.select { |p,k|  p if p == "color" || p == "name" || p == "size" || p == "category" }
		end

		def logs
			if @current_user.has_admin_access
				@store_logs = StoreLog.joins('INNER JOIN employees ON bucks_store_logs.employee_id = employees.IDnum').where('employees.property_id = ' + session[:property].to_s).search(params[:customer_id], params[:cashier_id], params[:purchase_id], params[:recent])
			else
				flash.now[:title] = 'Error'
				flash.now[:notice] = 'You do not have permission to view these logs.'
				render 'logs'
			end
		end

		def manage
			if @current_user.can_manage_inventory
				@top_favorited = Prize.where(property_id: session[:property]).top_favorited
				@top_purchased = Prize.where(property_id: session[:property]).top_purchased
				@prizes = Prize.where(property_id: session[:property]).search(params[:id], params[:name], params[:available]).order("#{sort_prize_column} #{sort_prize_direction}")
			else
				flash[:title] = 'Error'
				flash[:notice] = 'You do not have permission to manage the bucks store.'
				redirect_to controller: :employees, action: :home
			end
		end

		def new
			@prize = nil
			@prizes = Prize.all.group(:name).order(:name)
		end

		def show
			@prize = Prize.find(params[:id])
			@property_name = ::Property.find(session[:property]).name
			if @prize.must_order
				@inventories = Inventory.where(prize_id: @prize.id).order(price: :asc)
			else
				@inventories = Inventory.where(prize_id: @prize.id).where('bucks_inventories.stock > 0').order(price: :asc)
			end
			@images = @inventories.group(:image).map { |p| p.image if p.image != '' }
			@price_displayed = @inventories.group(:price).length == 1 ? "$" + @inventories.first.price.to_s : "Varied Prices"
			if !params[:inventory_id].blank?
				@chosen = Inventory.find(params[:inventory_id])
			else
				@chosen = @inventories.first
			end
			if @prize.category == 'Compensations' && !flash[:notice]
				flash[:title] = 'Warning'
				flash[:notice] = 'NOTICE: If you know the day in which you plan to use your comp, please enter it in the date below to ease the process. If you don\'t know the exact date, leave as Select Date.'
			end
			if @prize.limit && !flash[:notice]
				flash[:title] = 'Warning'
				flash[:notice] = 'NOTICE: Prize is limited to ' + @prize.limit.to_s + ' per person!'
			end
		end

		def stock
			@prize = Prize.find(params[:id])
		end

		def update
			@prize = Prize.find(params[:id])
			if(params.key?("cancel"))
	        	redirect_to action: :manage
	    	else
				if @current_user.can_manage_inventory
					if @prize.update_attributes(prize_params)

						flash[:title] = 'Success'
						flash[:notice] = @prize.name + ' has been updated.'
						StoreLog.new(:employee_id => @current_user.id, 
							:cashier_id => @current_user.id, 
							:prize_id => @prize.id,
							:trans => 'Updated').save
						redirect_to :action => 'manage'
					else
						flash.now[:title] = 'Error'
						flash.now[:notice] = @prize.errors.messages
						render 'edit'
					end
				else
					flash[:title] = 'Error'
					flash[:notice] = 'You do not have permission to edit items'
					redirect_to action: :index
				end
			end
		end

		private 
			def prize_params
				params.require(:prize).permit(:id, :name, :limit, :category, :in_store_only, :must_order, :available, :description, :featured, :request_date)
			end

	end
end