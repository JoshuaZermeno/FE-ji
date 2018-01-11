module Bucks
	class Api::V1::BucksController < Api::V1::BaseController

		include BucksHelper

		rescue_from ActiveRecord::RecordNotFound, with: :not_found

		before_filter :authenticate_user

		def not_found
			head status: 404
		end

		def approve
			@buck = Buck.find(params[:id])
			render(json: Api::V1::PendingBuckSerializer.new(@buck).to_json)
		end

		def create

			@buck = Buck.new(employee_id: params[:id].to_i, bucket_id: params[:bucket_id].to_i, 
				issuer_id: params[:issuer_id].to_i, value: params[:value].to_i, performed_at: params[:performed_at])

			valid_buck = true

			# Employee Panel Validation
			# Only accounts in and validates ID number. If number is blank, add error. If not blank, perform server validation.
		
			@employee = ::Employee.find(@buck.employee_id)
			@issuer = ::Employee.find(@buck.issuer_id)
			if @buck.employee_id == @issuer.IDnum
				@buck.errors.add(:reason, "Can't issue to yourself!")
				valid_buck = false
			end
			if !@employee.can_earn_bucks
				@buck.errors.add(:reason, "Ineligible to Earn")
				valid_buck = false
			end
			if @employee.property_id != @issuer.property_id
				@buck.errors.add(:reason, "Wrong Property")
				valid_buck = false
			end

			# Buck/Bucket Information Validation
			# If the user has not selected a bucket other than the default value on the selector (default value is "" contrary
			# to the name of the option which is Select Bucket) do not queue for the bucket, just print error. If an option
			# is selected, validate the options based around buck and bucket requirements
			
			@bucket = Bucket.find(@buck.bucket_id)
			# If the value has a range that must be entered
			if @bucket.value.nil?
				if @buck.value < @bucket.min || @buck.value > @bucket.max
					@buck.errors.add(:value, "Value Out of Range")
					valid_buck = false
				end
			end
			if @bucket.reason && params[:reason].blank?
				@buck.errors.add(:employee_id, "Reason Required")
				valid_buck = false
			end

			if @bucket.date && params[:performed_at].blank?
				@buck.errors.add(:performed_at, "Date Required")
				valid_buck = false
			end

			if valid_buck
				@department = ::Department.find(@employee.department_id)
				@buck.department_id = @employee.department_id
				@buck.number = assign_buck_number
				@buck.original_value = @buck.value
				@buck.performed_at = params[:performed_at].to_time if @bucket.date

				# If the issuer possesses the ability to approve bucks, it will skip the approval process and immediately go active
				if @buck.needs_approval(@issuer)
					@buck.status = "Pending"
					@buck.save
					Mailer.pending_buck_approval(@issuer, @buck).deliver_now if @department.has_valid_approvers
				else
					@buck.status = "Active"
					@buck.approved_at = Time.now
					@employee = ::Employee.find(@buck.employee_id)
					@buck.save
					Mailer.notify_employee(@buck, @employee).deliver_now if !@employee.email.blank?
				end

				buck_log_params = { :buck_id => @buck.id, 
					:event => 'Issued', 
					:performed_id => @issuer.id,
					:received_id => @employee.id,
					:value_before => @buck.value,
					:value_after => @buck.value,
					:status_before => @buck.status,
					:status_after => @buck.status }
				BuckLog.new(buck_log_params).save

				# if !@department.has_valid_approvers
				#	Mailer.mail_issue("Automatic email sent for issue: Department missing active approver.", "", @current_user)
				# end
				msg = { :status => "Success", :message => "Buck Issued!" }
	      render json: msg.to_json, status: 201
			else
				render json: @buck.errors.to_json, status: 409
			end
		end

		def index
			@bucks = Buck.where(employee_id: params[:id]).where(status: ['Active', 'Partial'])
			render json: @bucks, each_serializer: Api::V1::BuckSerializer
		end

		def new
			@property_id = ::Employee.find(params[:id]).property_id
			if params[:special] == "true"
				@buckets = Bucket.where(property_id: @property_id)
			else
				@buckets = Bucket.where(property_id: @property_id, special: false)
			end
			render json: @buckets.order(:name), each_serializer: Api::V1::BucketSerializer
		end

		def pending
			@bucks = ::Employee.find(params[:approver_id]).get_pending_bucks
			render json: @bucks, each_serializer: Api::V1::BuckSerializer
		end

		def show
			@buck = Buck.find(params[:id])
			render(json: Api::V1::BuckSerializer.new(@buck).to_json)
		end

		def update
			@buck = Buck.find(params[:id])
			@employee = ::Employee.find(@buck.employee_id)
			if params[:status] == 'Active'
				if @buck.is_valid_value(params[:value])
					@buck.update_attribute(:status, "Active")
					@buck.update_attribute(:approved_at, Time.now)
					@buck.update_attribute(:original_value, params[:value])
					@buck.update_attribute(:value, params[:value])

					approved_buck_log_params = { :buck_id => @buck.id,  
						:performed_id => @buck.issuer_id,
						:recieved_id => @buck.employee_id,
						:event => 'Activated',
						:value_before => @buck.value,
						:value_after => params[:buck][:value],
						:status_before => 'Pending',
						:status_after => 'Active' }
					BuckLog.new(approved_buck_log_params).save

					Mailer.notify_employee(@buck, ::Employee.find(@buck.employee_id)).deliver_now if !::Employee.find(@buck.employee_id).email.blank?
					Mailer.notify_issuer(@buck, ::Employee.find(@buck.issuer_id), ::Employee.find(@buck.employee_id), @current_user, "Approved", "Approved").deliver_now

					msg = { :status => "Success", :message => "Buck Approved!" }
		      render json: msg.to_json, status: 201
				else
					@buck.errors.add(:value, "Invalid Value")
		      render json: @buck.errors.to_json, status: 409
				end
			else
				@buck.update_attribute(:status, "Denied")
				Mailer.notify_issuer(@buck, ::Employee.find(@buck.issuer_id), ::Employee.find(@buck.employee_id), @current_user, "Denied", params[:buck][:denial_reason]).deliver_now
				msg = { :status => "Success", :message => "Buck Denied!" }
	      render json: msg.to_json, status: 201
			end
		end
	end
end