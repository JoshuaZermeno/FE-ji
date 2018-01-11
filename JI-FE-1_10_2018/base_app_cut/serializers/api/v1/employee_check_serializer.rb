class Api::V1::EmployeeCheckSerializer < ActiveModel::Serializer
	attributes :IDnum, :balance, :notifications

	def balance
		object.get_bucks_balance
	end

	def notifications
		Notification.where(to_id: object.IDnum).where(read: false).count
	end

end