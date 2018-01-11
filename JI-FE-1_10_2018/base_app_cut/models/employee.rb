# Apps Employee class with some methods excluded.
# This Employee model is the base model of a base app which uses common models such as Employee,
# Department, Job, etc. across multiple apps. Base logic is defined, but each engine extends
# off of this model to supply methods specific to the engine. 

class Employee < ActiveRecord::Base
	include Mysize::Employee
	include Bucks::Employee
	include Polls::Employee
	
	belongs_to   :property
	belongs_to 	 :job
	belongs_to	 :department

	self.primary_key = "IDnum"

  has_secure_password
  validates :password_digest, presence: true, {:with => /^.(?=.{6,})(?=.[a-z])(?=.[A-Z])(?=.[\d\W]).*$/, message: "Password must contain one or more: Uppercase letter, lowercase letter, number, and symbol. Minimum Length: 6"}


  def send_password_reset
    self.reset_key = SecureRandom.urlsafe_base64
    self.reset_key_time = DateTime.current
    save!
    Mailer.reset_password(self, key).deliver
  end

  scope :search, -> (id, first, last) { where('IDnum LIKE ? 
        AND first_name LIKE ? 
        AND last_name LIKE ?', "%#{id}%", "%#{first}%", "%#{last}%") }

  def self.filter(dept_ids, job_ids)
    if !dept_ids.nil? && !job_ids.nil?
      where(department_id: dept_ids,
      	job_id: job_ids).limit(10)
    elsif !dept_ids.nil? 
    	where(department_id: dept_ids)
    elsif !job_ids.nil?
    	where(job_id: job_ids)
    else
      all
    end
  end

  def full_name
    self.first_name + " " + self.last_name
  end

  def is_same_department(employee)
    return self.department_id == employee.department_id
  end

  def get_profile_picture
    @picture = Dir.glob("app/assets/images/profile_photos/*#{self.IDnum}.jpg").first
    if @picture.nil?
      return 'profile_photos/profilePlaceholder.png'
    else
      @picture = @picture.split('/')[4]
      return 'profile_photos/'+ @picture.to_s
    end
  end

  def generate_api_token
    loop do
      self.api_token = SecureRandom.base64(64)
      break unless Employee.find_by(api_token: api_token)
    end
    self.update_attribute(:api_token, api_token)
  end

end
