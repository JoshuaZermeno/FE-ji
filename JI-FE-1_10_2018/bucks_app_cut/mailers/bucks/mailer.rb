module Bucks
class Mailer < ApplicationMailer
	include ApplicationHelper
	include SessionsHelper
	include EmployeesHelper
	require 'fcm'

	default from: "bucks@hollywoodcasinotoledo.com"

	def mail_feedback(message, user)
		@from = user.full_name
		@message = message
		@jobcodes = ::Job.where(bucks_feedback: true)
		@jobcodes = @jobcodes.map { |f| f.jobcode }
		@recipients = Array.new
		@jobcodes.each do |f|
			::Employee.where(job_id: f).where(status: "Active").each do |e|
				@recipients.push(e.email)
			end
		end

		mail(to: @recipients, subject: 'Feedback: ' + @from)
	end

	def mail_issue(message, url, user)
		@from = user.full_name
		@message = message
		@url = url
		@jobcodes = ::Job.where(bucks_feedback: true)
		@jobcodes = @jobcodes.map { |f| f.jobcode }
		@recipients = Array.new
		@jobcodes.each do |f|
			::Employee.where(job_id: f).where(status: "Active").each do |e|
				@recipients.push(e.email)
			end
		end

		mail(to: @recipients, subject: 'Issue: ' + @from)
	end

	def notify_employee(buck, user)
		@user = user
		@buck = buck
		@issuer = ::Employee.find(buck.issuer_id)

		notification_params = { to_id: user.IDnum, 
			from_id: @issuer.IDnum, 
			read: false,
			target_id: @buck.number,
			category: Notification::NEW_BUCK }
		@notification = Notification.new(notification_params)
		@notification.save
		@push_receiver = ::Employee.find(@notification.to_id)
		if !@push_receiver.fcm_token.nil?
			fcm = FCM.new(Rails.application.secrets.fcm_key)
			push_fcm_tokens = Array.new
			push_fcm_tokens.push(@push_receiver.fcm_token)
			options = {data: {action: @notification.get_category, text: @notification.get_message}}
			fcm_response = fcm.send(push_fcm_tokens, options)
		end

		mail(to: user.email, subject: 'Buck Awarded!')
	end

	def notify_issuer(buck, issuer, employee, approver, decision, reason)
		@buck = buck
		@issuer = issuer
		@employee = employee
		@decision = decision
		@reason = reason

		if decision == 'Approved'
			notification_params = { to_id: issuer.IDnum, 
				from_id: approver.IDnum, 
				target_id: @buck.number,
				category: Notification::BUCK_APPROVED }
			@notification = Notification.new(notification_params)
			@notification.save
		else
			notification_params = { to_id: issuer.IDnum, 
				from_id: approver.IDnum, 
				target_id: @buck.number,
				category: Notification::BUCK_DENIED }
			@notification = Notification.new(notification_params)
			@notification.save
		end

		@push_receiver = ::Employee.find(@notification.to_id)
		if !@push_receiver.fcm_token.nil?
			fcm = FCM.new(Rails.application.secrets.fcm_key)
			push_fcm_tokens = Array.new
			push_fcm_tokens.push(@push_receiver.fcm_token)
			options = {data: {action: @notification.get_category, text: @notification.get_message}}
			fcm_response = fcm.send(push_fcm_tokens, options)
		end

		mail(to: @issuer.email, subject: 'Pending Buck Status')
	end

	def opt_in
		@user = ::Employee.find(params[:id])
		@user.update_attribute(:email, true)
		flash[:title] = 'Success'
		flash[:notice] = 'You will now receive email notifications from the bucks program!'
		redirect_to controller: :employee, action: :show, id: @current_user
	end

	def opt_out
		@user = ::Employee.find(params[:id])
		@user.update_attribute(:email, false)
		flash[:title] = 'Success'
		flash[:notice] = 'You will no longer receive email notifications from the bucks program.'
		redirect_to controller: :employee, action: :show, id: @current_user
	end


	def order_notify(prize, inventory, user, quantity, date)
		@user = user
		@prize = prize
		@inventory = inventory
		@quantity = quantity
		@date = date

		mail(to: ['Amy.Garcia@pngaming.com', 'Obdulia.Jiamachello@pngaming.com', 'Abby.Brown@pngaming.com', 'Amber.Ulrich@pngaming.com', 'Joshua.Zermeno@pngaming.com'], subject: 'New Prize Order')
	end

	def pending_buck_approval(user, buck)
		# Function to notify designated approvers that a buck is requiring approval.
		# user - issuer
		@user = user
		@buck = buck
		@employee = ::Employee.find_by(IDnum: buck.employee_id)
		@url = 'http://bucks.hollywoodcasinotoledo.com/bucks/pending/' + buck.number.to_s
		@approver1 = ::Department.find(@user.department_id).bucks_approve1
		@approver2 = ::Department.find(@user.department_id).bucks_approve2

		@approvers = Array.new
		::Employee.where(status: 'Active').where(job_id: @approver1).each do |e| 
			@approvers.push(e.email) if !e.nil?
			notification_params = { to_id: e.IDnum, 
				from_id: user.IDnum, 
				target_id: buck.number,
				category: Notification::PENDING_BUCK }
			@notification = Notification.new(notification_params)
			@notification.save

			@push_receiver = ::Employee.find(@notification.to_id)
			if !@push_receiver.fcm_token.nil?
				fcm = FCM.new(Rails.application.secrets.fcm_key)
				push_fcm_tokens = Array.new
				push_fcm_tokens.push(@push_receiver.fcm_token)
				options = {data: {action: @notification.get_category, text: @notification.get_message}}
				fcm_response = fcm.send(push_fcm_tokens, options)
			end
		end

		::Employee.where(status: 'Active').where(job_id: @approver2).each do |e| 
			@approvers.push(e.email) if !e.nil? 
			notification_params = { to_id: e.IDnum, 
				from_id: user.IDnum, 
				target_id: buck.number,
				category: Notification::PENDING_BUCK }
			@notification = Notification.new(notification_params)
			@notification.save

			@push_receiver = ::Employee.find(@notification.to_id)
			if !@push_receiver.fcm_token.nil?
				fcm = FCM.new(Rails.application.secrets.fcm_key)
				push_fcm_tokens = Array.new
				push_fcm_tokens.push(@push_receiver.fcm_token)
				options = {data: {action: @notification.get_category, text: @notification.get_message}}
				fcm_response = fcm.send(push_fcm_tokens, options)
			end
		end

		if !@approvers.empty?
			mail(to: @approvers, subject: 'Buck Requiring Approval')
		end
	end

	def reset_password(user, key)
		@to = user.email
		@key = key
		mail(to: @to, subject: 'Reset Password')
	end
end
end