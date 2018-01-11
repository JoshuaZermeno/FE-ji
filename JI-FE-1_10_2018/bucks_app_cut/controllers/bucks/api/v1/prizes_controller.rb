module Bucks
	class Api::V1::PrizesController < Bucks::Api::V1::BaseController

		rescue_from ActiveRecord::RecordNotFound, with: :not_found

		before_filter :authenticate_user

		def not_found
			return head status: 404
		end

		def index
			@inventory_search_result = Inventory.search_store(params[:size], params[:color])
			@inventory_search_result_ids = Array.new
			@inventory_search_result.each { |p| @inventory_search_result_ids.push(p.prize_id) }
			@inventory_search_result_ids.uniq!
			@prizes = Prize.where(id: @inventory_search_result_ids, property_id: params[:property_id], available: true, in_store_only: false)
			@prizes = @prizes.search_store(params[:name], params[:category], params[:balance]).order(:name)
			render json: @prizes, each_serializer: Api::V1::PrizeSerializer
		end

		def colors
			Inventory.where(prize_id: object.id).group(:color)
		end

		def show
			@prize = Prize.find(params[:id])
			if @prize.must_order
				@ivnentories = Inventory.where(prize_id: params[:id]).order(price: :asc)
			else
				@ivnentories = Inventory.where(prize_id: params[:id]).where("stock > 0").order(price: :asc)
			end
			
			render json: @ivnentories, each_serializer: Api::V1::InventorySerializer
		end
	end
end