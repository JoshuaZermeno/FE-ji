module Bucks
class Api::V1::SessionsController < Bucks::Api::V1::BaseController
	# Stateless API session creation. Returns user info to mobile
	# device where data is used throughout app.

  # Called after successful auth hub login where device has received
	# a verfied API token. New token is used to authenticate identify
	# and the fcm_token for the app on the device is passed to this API
	# to recieve notifcations. Basic user data is also sent to be stored
	# on the device's preferences.
  def dock
    employee = Employee.find_by(IDnum: params[:id], api_token: params[:token])
    if !employee.nil? 
      employee.update_attribute(:fcm_token, params[:fcm_token])
      render(json: Api::V1::SessionSerializer.new(employee, root: false).to_json, status: 201)
    else
      msg = { :status => "ERROR", :message => "Invalid token" }
      render :json => msg, status: :unauthorized
    end
  end
end
end