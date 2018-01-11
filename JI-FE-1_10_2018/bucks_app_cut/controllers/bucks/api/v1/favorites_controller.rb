module Bucks
	class Api::V1::FavoritesController < Bucks::Api::V1::BaseController

		rescue_from ActiveRecord::RecordNotFound, with: :not_found

		before_filter :authenticate_user

		def not_found
			return head status: 404
		end

		def create
			if Favorite.find_by(employee_id: params[:id], inventory_id: params[:inventory_id]).blank?
				inventory = Inventory.find(params[:inventory_id])
				prize = Prize.find(inventory.prize_id)
				Favorite.create(employee_id: params[:id], prize_id: prize.id, inventory_id: params[:inventory_id]).save
				msg = { :status => "Success", :message => "Favorited" }
	      		render json: msg.to_json, status: 201
			else
				msg = { :status => "Error", :message => "Item already favorited" }
	      		render json: msg.to_json, status: 409
			end
		end

		def delete
			@favorite = Favorite.find_by(employee_id: params[:id], inventory_id: params[:inventory_id])
			if !@favorite.nil?
				@favorite.delete
				msg = { :status => "Success", :message => "Unfavorited" }
	      		render json: msg.to_json, status: 201
			else
				msg = { :status => "Error", :message => "Item was not favorited" }
	      		render json: msg.to_json, status: 409
			end
		end

		def index
			@favorites = Favorite.where(employee_id: params[:id])

			render json: @favorites, each_serializer: Api::V1::FavoriteSerializer
		end
	  
		def show
			@favorite = Favorite.find(params[:id])

			render(json: Api::V1::FavoriteSerializer.new(@favorite).to_json)
		end

	end
end