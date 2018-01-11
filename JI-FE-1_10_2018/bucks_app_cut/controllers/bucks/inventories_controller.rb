module Bucks
	class InventoriesController < Bucks::ApplicationController
		include SessionsHelper

		before_filter :authenticate_user_logged_in

		def create
			@prize = Prize.find(params[:id])
			@inventory = Inventory.new(inventory_params)
			@inventory.prize_id = @prize.id
			@inventory.image = @inventory.image

			if !@prize.must_order && params[:inventory][:stock].to_i < 0
				@prize.inventory.errors.add(:stock, "If item doesn't need to be ordered, a stock is required.")
			end

			if @current_user.can_manage_inventory
				if @inventory.save
					if @inventory.image.file.nil?
						@inventory.update_attribute(:image, 'no_image.png')
					end
					flash[:title] = 'Success'
					flash[:notice] = 'Prize type successfully added'
					StoreLog.new(:employee_id => @current_user.id, 
						:cashier_id => @current_user.id, 
						:prize_id => @prize.id,
						:inventory_id => @inventory.id,
						:trans => 'Created').save
					redirect_to :action => 'manage'
				else
					flash.now[:title] = 'Error'
					flash.now[:notice] = @inventory.errors.messages
					render 'new'
				end
			else
				flash[:title] = 'Error'
				flash[:notice] = 'You do not have permission to add items.'
				redirect_to :action => 'index'
			end
		end

		def destroy
			@inventory = Inventory.find(params[:id])
			if Purchase.where(inventory_id: @inventory.id).blank?
				StoreLog.where(inventory_id: @inventory.id).destroy_all
				@inventory.destroy
				flash[:title] = 'Success'
				flash[:notice] = 'Inventory item and it\'s logs have been deleted.'
				redirect_to controller: :inventories, action: :manage, id: @inventory.prize.id
			else
				flash[:title] = 'Error'
				flash[:notice] = { 'Errors' => ['Stock has related purchases and cannot be deleted.']}
				redirect_to controller: :inventories, action: :edit, id: @inventory.id
			end
		end

		def edit
			@inventory = Inventory.find(params[:id])
			@prize = Prize.find(@inventory.prize_id)
		end

		def manage
			@prize = Prize.find(params[:id])
			@inventories = Inventory.search_initialized(@prize.id, params[:size], params[:color], params[:details])
			@sizes = Array.new 
			@inventories.group(:size).each { |p| @sizes.push(p.size) }
			@colors = Array.new 
			@inventories.group(:color).each { |p| @colors.push(p.color) }
			@favorites = Favorite.where(prize_id: @prize.id).count
			@purchases = Purchase.where(prize_id: @prize.id).count
		end

		def prize

		end

		def new 
			@prize = Prize.find(params[:id])
			@inventory = nil
		end

		def update
			@inventory = Inventory.find(params[:id])
			if(params.key?("cancel"))
				redirect_to action: :manage
			else
				if @current_user.can_manage_inventory
					if @inventory.update(inventory_params)
						flash[:title] = 'Success'
						flash[:notice] = 'Inventory item successfully updated'
						Prize.find(@inventory.prize_id).update_availability
						StoreLog.new(:employee_id => @current_user.id, 
							:cashier_id => @current_user.id, 
							:prize_id => @inventory.prize_id,
							:inventory_id => @inventory.id,
							:trans => 'Updated').save
						redirect_to action: :manage, id: @inventory.prize_id
					else
						flash.now[:title] = 'Error'
						flash.now[:notice] = @inventory.errors.messages
						render 'edit'
					end
				else
					flash[:title] = 'Error'
					flash[:notice] = 'You do not have permission to edit items'
					redirect_to action: :manage
				end
			end
		end

		private
		def inventory_params
			params.require(:inventory).permit(:id, :prize_id, :price, :cost, :stock, :size, :color, :limit, :image, :description, :details)
		end

	end
end