module Bucks
	class FavoritesController < Bucks::ApplicationController
		include SessionsHelper
		include FavoritesHelper

		before_filter :authenticate_user_logged_in

		def analyze

		end

		def create
			flash[:title] = 'Success'
			@inventory = Inventory.find(params[:inventory_id])
			if Favorite.find_by(employee_id: @current_user.IDnum, inventory_id: @inventory.id).blank?
				Favorite.create(employee_id: @current_user.IDnum, prize_id: @inventory.prize_id, 
					inventory_id: @inventory.id).save
				flash[:notice] = Prize.find(@inventory.prize_id).name + ' was added to your favorites!'
			else
				flash[:notice] = Prize.find(@inventory.prize_id).name + ' is already in your favorites!'
			end
			redirect_to controller: :favorites, action: :index
		end

		def delete
			Favorite.find_by(employee_id: @current_user.IDnum, inventory_id: params[:inventory_id]).delete
			@inventory = Inventory.find(params[:inventory_id])
			if params[:source] == 'shop'
				flash[:title] = 'Success'
				flash[:notice] = Prize.find(@inventory.prize_id).name + ' has been removed from your favorites.'
				redirect_to controller: :prizes, action: :show, id: params[:inventory_id]
			else
				flash[:title] = 'Success'
				flash[:notice] = Prize.find(@inventory.prize_id).name + ' has been removed from your favorites.'
				redirect_to controller: :favorites, action: :index
			end
		end

		def index
			@favorites = Favorite.where(employee_id: @current_user.id)
			@balance = @current_user.get_bucks_balance
		end

		def new

		end

	end
end