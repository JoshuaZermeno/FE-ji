class Api::V1::EmployeeSimpleSerializer < ActiveModel::Serializer
	attributes :id, :IDnum, :full_name, :created_at, :updated_at, :image, :earn, :issue, :issue_special

	belongs_to :department
	belongs_to :job

	def created_at
		object.created_at.in_time_zone.iso8601 if object.created_at
	end

	def updated_at
		object.updated_at.in_time_zone.iso8601 if object.created_at
	end

	def earn
		Job.find(object.job_id).roles.exists?(recieve: true) && object.status == "Active" ? true : false
	end

	def image
		object.get_profile_picture
	end
	
	def issue
		Job.find(object.job_id).roles.exists?(issue: true) && object.status == "Active" ? true : false
	end

	def issue_special
		Job.find(object.job_id).roles.exists?(issue: true) && object.status == "Active" ? true : false
	end

end