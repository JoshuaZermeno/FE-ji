module Bucks
	class Api::V1::SessionSerializer < ActiveModel::Serializer
	  #just some basic attributes
	  attributes :id, :IDnum, :name, :property_id, :property_name, :balance, :image, :job_id, :job_title, :department_id, :department_name, :issue, :issue_special, :approve, :token

	  def name
	    object.full_name
	  end

	  def balance
	    object.get_bucks_balance
	  end

	  def property_name
	    ::Property.find(object.property_id).name
	  end

	  def department_name
	    ::Department.find(object.department_id).name
	  end

	  def job_title
	    ::Job.find(object.job_id).title
	  end

	  def issue
	  	object.can_issue_bucks
	  end 

	  def issue_special
	  	object.can_issue_special_bucks
	  end

	  def approve
	  	object.can_approve_bucks
	  end
	  
	  def image
	    object.get_profile_picture
	  end

	  def token
	  	object.api_token
	  end
	end
end