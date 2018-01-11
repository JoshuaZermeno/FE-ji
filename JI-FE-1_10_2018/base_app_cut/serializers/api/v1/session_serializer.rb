class Api::V1::SessionSerializer < ActiveModel::Serializer
  #just some basic attributes
  attributes :id, :IDnum, :name, :property_id, :property_name, :balance, :image, :job_id, :job_title, :department_id, :department_name, :issue, :issue_special, :approve

  def name
    Employee.find(object.IDnum).full_name
  end

  def balance
    Employee.find(object.IDnum).get_bucks_balance
  end

  def property_name
    Property.find(Employee.find(object.IDnum).property_id).name
  end

  def department_name
    Department.find(Employee.find(object.IDnum).department_id).name
  end

  def job_title
    Job.find(Employee.find(object.IDnum).job_id).title
  end

  def issue
  	Employee.find(object.IDnum).can_issue_bucks
  end 

  def issue_special
  	Employee.find(object.IDnum).can_issue_special_bucks
  end

  def approve
  	jobcode = Employee.find(object.IDnum).job_id
  	!Department.where('approve1 = ? OR approve2 = ?', jobcode.to_s, jobcode.to_s).empty?
  end
  
  def image
    Employee.find(object.IDnum).get_profile_picture
  end
end