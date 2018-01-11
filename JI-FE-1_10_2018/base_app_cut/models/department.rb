class Department < ActiveRecord::Base
	include Bucks::Department
	
	has_many :employees
	belongs_to :property

end
