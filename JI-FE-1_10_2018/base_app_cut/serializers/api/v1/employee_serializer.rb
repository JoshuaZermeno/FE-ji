class Api::V1::EmployeeSerializer < ActiveModel::Serializer
	attributes :id, :IDnum, :access, :first_name, :last_name, :department_id, :created_at, :updated_at, :image, :password_digest, :job_id, :email, :status, :earn, :issue, :issue_special, :balance, :notify, :reset_key, :reset_key_time, :hired, :new_pass, :rankings

	belongs_to :department
	belongs_to :job
	has_many :to, serializer: Api::V1::NotificationSerializer

	def access
		object.has_general_access
	end

	def balance
		object.get_bucks_balance
	end

	def created_at
		object.created_at.in_time_zone.iso8601 if object.created_at
	end

	def earn
		object.can_earn_bucks
	end

	def image
		object.get_profile_picture
	end
	
	def issue
		object.can_issue_bucks
	end

	def issue_special
		object.can_issue_special_bucks
	end

	def updated_at
		object.updated_at.in_time_zone.iso8601 if object.created_at
	end

	def rankings
		@buckets = Bucket.where(property_id: object.property_id, rankings: true).order(:name)
		ActiveModel::SerializableResource.new(@buckets, employee_id: object.IDnum, each_serializer: Api::V1::RankSerializer)
	end
end