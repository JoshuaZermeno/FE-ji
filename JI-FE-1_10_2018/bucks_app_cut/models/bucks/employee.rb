# The main large app, the Bucks program, has many relations and methods specific to itself, so it is all kept in an Employee
# module in the app that in included in the base model by including through the engine "gem".
module Bucks
	module Employee
		def self.included(base)
      base.class_eval do 

			  has_many :favorites
			  has_many :bucks
			  has_many :purchases
			  has_many :to, class_name: 'Bucks::Notification', foreign_key: 'to_id'
			  has_many :from, class_name: 'Bucks::Notification', foreign_key: 'from_id'

			  def has_admin_access?
			    ::Job.find(self.job_id).bucks_admin
			  end

			  # Covers all boolean columns that contain access permissions. 
			  # Designed to be verbs: earn, issue, order, manage_inventory
				(::Job.column_names - ["id", "jobcode", "title", "created_at", "updated_at"]).each do |permission|
			    define_method "can_#{permission}?" do
			      ::Job.find(self.job_id)[permission]
			    end
				end

			  # SPECIFIC ACTIONS USING PERMISSION
			  def can_view_employee(employee)
			    return (self.can_view_dept? && self.is_same_department(employee) && self.can_view_all?
			  end

			  def can_view_buck(buck)
			    employee = ::Employee.find(buck.employee_id)
			    return self.id == buck.employee_id || self.id == buck.issuer_id || (self.can_view_dept? && self.is_same_department(employee)) || self.can_view_all?
			  end

			  def get_bucks_balance
			    return Buck.where(employee_id: self.id).where(status: ['Active', 'Partial']).sum(:value)
			  end

			  def get_amount_earned_month(month)
			      return Buck.where.not(status: 'Void').where(employee_id: self.IDnum).where('extract(month from approved_at) = ?', month).sum(:original_value)
			  end

			  def get_amount_earned_year(year)
			    return Buck.where.not(status: 'Void').where(employee_id: self.IDnum).where('extract(year from approved_at) = ?', year).sum(:original_value)
			  end

			  def get_bucks_earned_month(month)
			      return Buck.where.not(status: 'Void').where(employee_id: self.IDnum).where('extract(month from approved_at) = ?', month).count
			  end

			  def get_bucks_earned_year(year)
			    return Buck.where.not(status: 'Void').where(employee_id: self.IDnum).where('extract(year from approved_at) = ?', year).count
			  end

			  # Check if employee is a designated approver for departments. Find bucks he/she must approve within those departments.
			  def get_pending_bucks
			    jobcode = self.job_id
			    approve_for = ::Department.where('bucks_approve1 = \'' + jobcode + '\' OR bucks_approve2 = \'' + jobcode + '\'')
			    bucks = Array.new
			    approve_for.each { |d| Buck.joins('INNER JOIN employees ON bucks_bucks.issuer_id = employees.IDnum WHERE employees.department_id = ' + d.id.to_s + ' AND bucks_bucks.status = "Pending"').each { |b| bucks.push(b) }}
			    return bucks
			  end

			  def get_personal_budget_used(month, year)
			    Buck.where('extract(month from approved_at) = ? AND extract(year from approved_at) = ?', "#{month}", "#{year}").where(issuer_id: self.id).where('status <> "Void"').count
			  end

			  def get_department_budget_used_percent(month, year)
			    department = ::Department.find(self.department_id)
			    get_personal_budget_used(month, year).to_f > 0 ? ((get_personal_budget_used(month, year).to_f / department.get_budget_overall.to_f) * 100).round(2) : 0
			  end

			  def is_over_budget?(month, year)
			    self.get_personal_budget_used(month, year) > ::Department.find(self.department_id).get_budget_per_employee
			  end

			  def get_unread_notification_count
			    return Notification.where(to: self).where(read: false).count
			  end

			  def get_unread_notifications
			    return Notification.where(to: self).where(read: false).order(created_at: :desc)
			  end

			  # Used in correlation with prize limits that adhere to the prize, not just the inventory.
			  def purchase_count(prize)
			  	case prize.class.name.demodulize
			  	when "Prize"
			    	Purchase.where(employee_id: self.IDnum).where(prize_id: prize.id).where(returned: false).count
			    when "Inventory"
			    	Purchase.where(employee_id: self.IDnum).where(inventory_id: prize.id).where(returned: false).count
			    else
			    	0
			    end
			  end

			  def has_reached_purchase_limit(item)
			    purchase_count(item) >= item.limit
			  end

			  def get_rank_for_bucket(bucket_id)
			    @earned_count = Buck.where(employee_id: self.IDnum, bucket_id: bucket_id).where.not(status: 'Void').count
			    if @earned_count == 0
			      return '-'
			    else
			      rank = (Buck.where(bucket_id: bucket_id).group(:employee_id).count.values.sort.reverse.uniq.find_index(@earned_count) + 1).to_s
			      if !rank.nil?
			        return '#' + rank
			      else
			        return "error"
			      end
			    end
			  end

			  # Old code from old schema. Ranks top employees who earn in this category. Above method now sued.
			  #scope :top_attendance, -> {
			  #  select("employees.id, count(bucks_bucks.id) AS bucks_count").
			  #  joins(:bucks).
			  #  where("bucks_bucks.reason_short='Attendance' AND bucks_bucks.status <> 'Void' AND employees.status <> 'Terminated'").
			  #  group("employees.id").
			  #  order("bucks_bucks_count DESC").
			  #  limit(5) }

			end
		end
	end
end