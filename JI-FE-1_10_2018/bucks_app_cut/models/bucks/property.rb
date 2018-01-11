module Bucks
	class Property < ActiveRecord::Base
		has_many :employees
		has_many :jobcodes
		has_many :prizes
		has_many :departments
		has_many :slide_images

		self.primary_key = 'code'
	end
end