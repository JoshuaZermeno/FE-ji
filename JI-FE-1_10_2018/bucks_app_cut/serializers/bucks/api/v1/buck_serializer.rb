module Bucks
	class Api::V1::BuckSerializer < ActiveModel::Serializer
		attributes :number, :employee_id, :employee_name, :value, :status, :assignedBy, :department_id, :department_name, :bucket_id, :bucket_name, :reason, :approved_at, :created_at

		def employee_name
			::Employee.find(object.employee_id).full_name
		end

		def assignedBy
			# Mobile systems don't need to know any other IDs of employees since
			# they do not hold the employee information to process offline without
			# finding the information from the server each load. Uploads and 
			# new bucks send IDs because server can process.
			::Employee.find(object.issuer_id).full_name
		end

		def bucket_name
			Bucket.find(object.bucket_id).name
		end

		def department_name
			::Department.find(object.department_id).name
		end

		def approved_at
			object.approved_at.in_time_zone.iso8601 if object.approved_at
		end

		def created_at
			object.created_at.in_time_zone.iso8601 if object.created_at
		end

		def updated_at
			object.updated_at.in_time_zone.iso8601 if object.created_at
		end
	end
end