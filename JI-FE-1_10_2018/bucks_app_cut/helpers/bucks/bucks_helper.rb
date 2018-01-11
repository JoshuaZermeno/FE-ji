module Bucks
	module BucksHelper
		include SessionsHelper

		def assign_buck_number
			@highest_buck = Buck.order(number: :desc).first
			return @highest_buck.number + 1
		end

		def can_employee_afford_prize(employee, prize)
			get_bucks_balance(employee) > prize.cost
		end

		def getBuckValue(reason)
			if reason.eql?("A+ Service")
				return 20
			elsif reason.eql?("Attendance")
				return 3
			elsif reason.eql?("Innovation/Initiative")
				return 3
			elsif reason.eql?("InnovationInitiative")
				return 3
			elsif reason.eql?("Shift Coverage")
				return 2
			elsif reason.eql?("Customer Service")
				return 5
			elsif reason.eql?("Community Involvement")
				return 3
			elsif reason.eql?("Birthday")
				return 20
			else
				return 10
			end
		end

		def cleanBuckOriginalValues
			Buck.all.each do |b|
				value = getBuckValue(b.reason_short)
				if value != 10
					b.update_attribute(:original_value, value)
				end
			end
		end

		def setVoidBucksToZeroValue
			Buck.all.where(status: "Void").update_all(value: 0)
		end

		def getBuckStyle(reason_short) 
			return case reason_short
			when "Birthday"
				"buck-container-birthday"
			when "A+ Service"
				"buck-container-gold"
			else
				"buck-container-default"
			end
		end

		def p_class_for_budget(used, budget)
			if used <= budget
				return 'text-success'
			elsif used > budget && used < ((budget * 0.15) + budget)
				return 'text-warning'
			else
				return 'text-danger'
			end
		end

		def assign_buckets_to_bucks
			Buck.group(:reason_short).each do |b|
				@bucket = Bucket.where(name: b.reason_short).first
				Buck.where(reason_short: b.reason_short).update_all(bucket_id: @bucket.id)
			end
		end

		def import_buckets_data
			@bucks_array = CSV.read("#{Rails.root}/app/assets/bucket_data.csv")

			@bucks_array.each do |b|
					Buck.find_by(number: b[0]).update_attribute(:bucket_id, Bucket.find_by(name: b[1]).id)
			end
		end

	end
end