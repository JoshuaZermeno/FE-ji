class Mailer < ApplicationMailer

	include ApplicationHelper
	default from: "hrapps@hollywoodcasinotoledo.com"

	def reset_password(user, key)
		@to = user.email
		@key = key
		mail(to: @to, subject: 'Reset Password')
	end

end