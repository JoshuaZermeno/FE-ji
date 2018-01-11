module Bucks
  class Notification < ActiveRecord::Base
		belongs_to :to, class_name: 'Employee'
		belongs_to :from, class_name: 'Employee'

		ACHIEVEMENT = "ACHIEVEMENT"
		NEW_BUCK = "NEW_BUCK"
		BUCK_APPROVED = "BUCK_APPROVED"
		BUCK_DENIED = "BUCK_DENIED"
		PENDING_BUCK = "PENDING_BUCK"
		PENDING_ORDER = "PENDING_ORDER"
		REFUND_PRIZE = "REFUND_PRIZE"
		ORDER_COMPLETE = "ORDER_COMPLETE"

		def get_target_url
			case self.category
				when ACHIEVEMENT
					return '/bucks/employees/' + self.to_id.to_s + '/achievements'
				when NEW_BUCK, BUCK_APPROVED, BUCK_DENIED
					return '/bucks/bucks/' + self.target_id.to_s
				when PENDING_BUCK
					return '/bucks/bucks/pending/' + self.target_id.to_s
				when PENDING_ORDER
					return '/bucks/admin/orders'
				when ORDER_COMPLETE
					return '/bucks/notifications?utf8=✓&notification_id=' + self.id.to_s
				when REFUND_PRIZE
					return '/bucks/notifications?utf8=✓&notification_id=' + self.id.to_s
				else
					return '#'
			end
		end

		def get_category
			case self.category
				when ACHIEVEMENT
					return 'New Achievement'
				when NEW_BUCK
					return 'New Buck'
				when BUCK_APPROVED
					return 'Buck Approved'
				when BUCK_DENIED
					return 'Buck Denied'
				when PENDING_BUCK
					return 'Pending Buck'
				when PENDING_ORDER
					return 'Pending Order'
				when ORDER_COMPLETE
					return 'Order Complete'
				when REFUND_PRIZE
					return 'Prize Refunded'
				else
					return 'New Notification'
			end
		end

		def get_message
			case self.category
				when ACHIEVEMENT
					return 'You\'ve earned an achievement!'
				when NEW_BUCK
					return 'You\'ve been awarded $' + Buck.find(self.target_id).original_value.to_s + ' for ' + Bucket.find_by(id: Buck.find(self.target_id).bucket_id).name + '!'
				when BUCK_APPROVED
					return 'Buck request has been approved'
				when BUCK_DENIED
					return 'Buck request has been denied'
				when PENDING_BUCK
					return 'Buck requiring approval'
				when PENDING_ORDER
					return 'New order for ' + Prize.find(self.target_id).name
				when ORDER_COMPLETE
					return 'Order for ' + Prize.find(self.target_id).name + ' completed!'
				when REFUND_PRIZE
					return 'You\'ve been refunded $' + Prize.find(self.target_id).price.to_s + ' for your purchase of '  + Prize.find(self.target_id).name
				else
					return 'New notification'
			end
		end
  end
end
