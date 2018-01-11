
class Api::V1::SessionsController < Api::V1::BaseController
	# Stateless API session creation. Returns user info to mobile
	# device where data is used throughout app.
	
  def create
    beta_depts = [6,8,11,20,33,5,10,13,9,27,29,7]
    user = Employee.find_by(IDnum: create_params[:IDnum])
    if user && user.authenticate(create_params[:password])
      if user.has_general_access && beta_depts.include?(user.department_id)
        user.generate_api_token
        render(
          json: Api::V1::SessionSerializer.new(user, root: false).to_json,
          status: 201)
      else
        msg = { :status => "ERROR", :message => "App access not granted. Please try again later or contact Human Resources." }
        render :json => msg, status: :unauthorized
      end
    else
      msg = { :status => "ERROR", :message => "Invalid ID number and password combination" }
      render :json => msg, status: :unauthorized
    end
  end
  
   private
  def create_params
    params.require(:employee).permit(:IDnum, :password)
  end

end
