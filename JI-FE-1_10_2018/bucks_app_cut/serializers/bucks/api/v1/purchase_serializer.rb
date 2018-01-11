module Bucks
	class Api::V1::PurchaseSerializer < ActiveModel::Serializer
		attributes :status, :pickedup_by, :created_at, :updated_at, :count

		belongs_to :prize
		belongs_to :inventory

		def count
			Purchase.where(employee_id: object.employee_id, prize_id: object.prize_id, returned: false).count
		end

		def created_at
			object.created_at.in_time_zone.iso8601 if object.created_at
		end

		def updated_at
			object.updated_at.in_time_zone.iso8601 if object.created_at
		end
	end
end