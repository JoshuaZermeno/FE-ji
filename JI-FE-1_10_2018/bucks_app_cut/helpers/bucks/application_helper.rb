module Bucks
	module ApplicationHelper

		require 'date'

		def buck_sortable(column, title = nil)
		  title ||= column.titleize
		  css_class = column == sort_buck_column ? "current #{sort_buck_direction}" : nil
		  direction = column == sort_buck_column && sort_buck_direction == "asc" ? "desc" : "asc"
		  link_to title, {:sort => column, :direction => direction,
		  	:search_number => params[:search_number], 
		  	:search_recipient_id => params[:search_recipient_id], 
		  	:search_issuer_id => params[:search_issuer_id],
		  	:show => params[:show]}, {:class => css_class}
		end

		def employee_sortable(column, title = nil)
		  title ||= column.titleize
		  css_class = column == sort_buck_column ? "current #{sort_buck_direction}" : nil
		  direction = column == sort_buck_column && sort_buck_direction == "asc" ? "desc" : "asc"
		  link_to title, {:sort => column, :direction => direction,
		  	:search_number => params[:search_number], 
		  	:search_recipient_id => params[:search_recipient_id], 
		  	:search_issuer_id => params[:search_issuer_id]}, {:class => css_class}
		end


		def prize_sortable(column, title = nil)
		  title ||= column.titleize
		  css_class = column == sort_prize_column ? "current #{sort_prize_direction}" : nil
		  direction = column == sort_prize_column && sort_prize_direction == "asc" ? "desc" : "asc"
		  link_to title, {sort: column, direction: direction, color: params[:color],
		  	name: params[:name], size: params[:size], available: params[:available]}, {:class => css_class}
		end

		def get_profile_picture(user_id)
			@picture = Dir.glob("app/assets/images/profile_photos/*#{user_id}.jpg").first
			if @picture.nil?
				return 'profile_photos/profilePlaceholder.png'
			else
				@picture = @picture.split('/')[4]
				return 'profile_photos/'+ @picture.to_s
			end
		end

		def get_trophy_based_on_rank(rank)
			case rank
			when '#1'
				return 'fa fa-trophy trophy-gold'
			when '#2'
				return 'fa fa-trophy trophy-silver'
			when '#3'
				return 'fa fa-trophy trophy-bronze'
			else
			end
		end

		def sortable_prize_columns
		  ["name", "price"]
		end

		def sort_prize_column
		  sortable_prize_columns.include?(params[:sort]) ? params[:sort] : "name"
		end

		def sort_prize_direction
		  %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
		end

		def sort_buck_column
	    	Buck.column_names.include?(params[:sort]) ? params[:sort] : "number"
	  	end
	  
		def sort_buck_direction
			%w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
		end

		def get_day_from_datepicker(date)
			DateTime.strptime(date, '%Y/%m/%d').day
		end

		def get_month_from_datepicker(date)
			DateTime.strptime(date, '%Y/%m/%d').month
		end

		def get_year_from_datepicker(date)
			DateTime.strptime(date, '%Y/%m/%d').year
		end

	end
end
