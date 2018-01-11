module Bucks
	class Api::V1::NotificationSerializer < ActiveModel::Serializer
		attributes :id, :to_id, :from_id, :from_name, :from_image, :target_id, :message, :read, :category, :created_at, :updated_at

		def from_name
			::Employee.find(object.from_id).full_name
		end

		def from_image
			::Employee.find(object.from_id).get_profile_picture
		end

		def message
			object.get_message
		end

		def created_at
			object.created_at.in_time_zone.iso8601 if object.created_at
		end

		def updated_at
			object.updated_at.in_time_zone.iso8601 if object.created_at
		end
	end
end