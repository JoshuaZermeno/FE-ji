class Job < ActiveRecord::Base
	include Mysize::Job

	has_many 	:employees
	
	self.primary_key = 'jobcode'

	def self.search_all(jobcode, title)
	  if jobcode || title 
			where('jobcode LIKE ? 
	      AND title LIKE ?', "%#{jobcode}%", "%#{title}%")
	  else
	    Job.all
	  end
	end
end
