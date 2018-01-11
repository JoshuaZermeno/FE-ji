module Bucks
  class Buck < ActiveRecord::Base
  	belongs_to :employee, class_name: '::Employee'
  	belongs_to :issuer, class_name: '::Employee', foreign_key: :issuer_id
	  belongs_to :department
	  belongs_to :bucket
		self.primary_key = 'number'

		scope :search, ->(number, recipient, issuer) { 
			if number || recipient || issuer
	      where('number LIKE ? 
	        AND employee_id LIKE ? 
	        AND issuer_id LIKE ?', "%#{number}%", "%#{recipient}%", "%#{issuer}%")
	    else
	      all.limit(20)
	    end
		}

		scope :floating, -> { where("bucks_bucks.status = 'Active' OR bucks_bucks.status = 'Pending' OR bucks_bucks.status = 'Partial'")}

	  def self.search_dept(dept, month, year)
	  	month = Date::MONTHNAMES.index(month) 
	    if !month.blank? && !year.blank?
	    	where('bucks_bucks.department_id = ? ', "#{dept}")
	    	.where('extract(year  from approved_at) = ?
	        AND extract(month from approved_at) = ?', "#{year}", "#{month}")
	      .where('bucks_bucks.status <> "Void"')
	    elsif !month.blank? 
	    	where('bucks_bucks.department_id = ? ', "#{dept}")
	    	.where('extract(month from approved_at) = ?', "#{month}")
	      .where('bucks_bucks.status <> "Void"')
	    elsif !year.blank?
	    	where('bucks_bucks.department_id = ? ', "#{dept}")
	    	.where('extract(year  from approved_at) = ?', "#{year}")
	      .where('bucks_bucks.status <> "Void"')
	    end
	  end

	  def self.get_from_month(month, year)
	    if !month.nil? && !year.nil?
	      month = Date::MONTHNAMES.index(month) 
	      where('extract(year from bucks_bucks.approved_at) = ?
	        AND extract(month from bucks_bucks.approved_at) = ?', "#{year}", "#{month}")
	      .where('bucks_bucks.status <> "Void" AND bucks_bucks.status <> "Denied"')
	    end
	  end

	  def self.get_from_quarter(q, year)
	    if !q.nil? && !year.nil?
	      q = q.to_i
	      where('extract(year from bucks_bucks.approved_at) = ?
	        AND (extract(month from bucks_bucks.approved_at) = ?
	        OR extract(month from bucks_bucks.approved_at) = ?
	        OR extract(month from bucks_bucks.approved_at) = ?)', "#{year}", "#{(3*q)-2}", "#{(3*q)-1}", "#{(3*q)}")
	      .where('bucks_bucks.status <> "Void" AND bucks_bucks.status <> "Denied"')
	    end
	  end

	  scope :get_from_year, -> (year) {
	  	where('extract(year from bucks_bucks.approved_at) = ?', "#{year}")
	      .where('bucks_bucks.status <> "Void" AND bucks_bucks.status <> "Denied"') if !year.nil?
	  }

	  def approved_this_month?
			this_month = Time.now.strftime("%m")
			this_year = Time.now.strftime("%Y")
			self.approved_at.strftime("%m") == this_month && self.approved_at.strftime("%Y") == this_year
		end

	  def needs_approval(issuer)
	    Bucket.find(self.bucket_id).approval && !(issuer.can_issue_special_bucks || issuer.can_approve_bucks)
	  end

	  def self.sort_by_name
	    self.sort_by(&:get_employee_name).reverse
	  end

	  def get_employee_name
	    ::Employee.find(self.employee_id).full_name
	  end

	  def dept_to_issuer
	      self.update_attribute(:department_id, ::Department.find(::Employee.find(self.issuer_id).department_id).id)
	  end

	  def dept_to_employee
	      self.update_attribute(:department_id, ::Department.find(::Employee.find(self.employee_id).department_id).id)
	  end

	  def is_valid_value(value)
	    bucket = Bucket.find(self.bucket_id)
	    if bucket.value.nil?
	      return true if value == bucket.value
	    else
	      return true if value >= bucket.min && value <= bucket.max
	    end
	    return false
	  end
  end
end
