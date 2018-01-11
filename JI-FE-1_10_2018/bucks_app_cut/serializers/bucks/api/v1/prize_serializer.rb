module Bucks
	class Api::V1::PrizeSerializer < ActiveModel::Serializer
		attributes :id, :name, :display_price, :must_order, :available, :featured, :category, :image, :request_date

		def image
			image = Prize.find(object.id).get_first_image
			image.nil? ? "" : image
		end

		def display_price
			@inventories = Inventory.where(prize_id: object.id).order(:price)
	    	@inventories.group(:price).length == 1 ? "$" + @inventories.first.price.to_s : "$" + @inventories.first.price.to_s + " - $" + @inventories.last.price.to_s
		end

		def created_at
			object.created_at.in_time_zone.iso8601 if object.created_at
		end

		def updated_at
			object.updated_at.in_time_zone.iso8601 if object.created_at
		end
	end
end