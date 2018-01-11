module Bucks
  class Purchase < ActiveRecord::Base
  	include ApplicationHelper

	  require 'date'

		belongs_to :prize
	  belongs_to :inventory
	  belongs_to :employee, class_name: '::Employee'

		def self.get_from_month(month, year)
	    if !month.nil? && !year.nil?
	      month = Date::MONTHNAMES.index(month) 
	      where('extract(year from bucks_purchases.created_at) = ?
	        AND extract(month from bucks_purchases.created_at) = ?', "#{year}", "#{month}")
	    end
	  end

	  def self.get_from_year(year)
	    if !year.nil?
	      where('extract(year from bucks_purchases.created_at) = ?', "#{year}")
	    end
	  end

	  def self.get_from_quarter(q, year)
	    if !q.nil? && !year.nil?
	      q = q.to_i
	      where('extract(year from bucks_purchases.created_at) = ?
	        AND (extract(month from bucks_purchases.created_at) = ?
	        OR extract(month from bucks_purchases.created_at) = ?
	        OR extract(month from bucks_purchases.created_at) = ?)', "#{year}", "#{(3*q)-2}", "#{(3*q)-1}", "#{(3*q)}")
	    end
	  end

	  def self.search(employee_id, first, last, date)
	    if !date.blank?
	      date = DateTime.strptime(date, '%Y-%m-%d')
	    end
	    if (!employee_id.blank? || !first.blank? || !last.blank?) && !date.blank?
	      where("employees.IDnum LIKE ? OR employees.first_name LIKE ? OR employees.last_name LIKE ?",
	        employee_id, first, last).where('extract(day from bucks_purchases.created_at) = ?
	        AND extract(month from bucks_purchases.created_at) = ?
	        AND extract(year from bucks_purchases.created_at) = ?', 
	        date.day, date.month, date.year)
	    elsif (!employee_id.blank? || !first.blank? || !last.blank?) && date.blank?
	      where("employees.IDnum LIKE ? OR employees.first_name LIKE ? OR employees.last_name LIKE ?",
	        employee_id, first, last)
	    elsif !date.blank?
	      where('extract(day from bucks_purchases.created_at) = ?
	        AND extract(month from bucks_purchases.created_at) = ?
	        AND extract(year from bucks_purchases.created_at) = ?', 
	        date.day, date.month, date.year)
	    else
	      first(20)
	    end
	  end
  end
end
