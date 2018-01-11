module Bucks
	class ReportBuilder

		def initialize(params)
			@@property = params[:property]
			@@month = params[:month]
			@@year = params[:year]
			@@quarter = params[:quarter]
		end

		def build_bucket_reports
			@month
		end

		def build_budget_reports
			budget_data_hash = Hash.new
			@buckets = Bucket.where(property_id: @@property).order(:name)
			::Department.where(property_id: @@property).each do |d|
				department_hash = Hash.new
				@month_num = Date::MONTHNAMES.index(@@month)
				@issued = Buck.get_from_month(@@month, @@year).joins(:employee, :issuer).where('employees.department_id = ' + d.id.to_s).where("employees.property_id = ?", @@property)
				department_hash["issued_percent"] = ((@issued.count.to_f / d.bucks_budget.to_f) * 100).round(2).to_s + "%"
				department_hash["issued_count"] = @issued.count

				@internal = @issued.where('bucks_bucks.department_id = ' + d.id.to_s)
				@external = @issued.where('bucks_bucks.department_id <> ' + d.id.to_s)
				@internal_total = @internal.count
				@external_total = @external.count
				@total = @internal_total + @external_total
				@internal_percent = ((@internal_total.to_f / @total.to_f) * 100).round(2)
				@external_percent = ((@external_total.to_f / @total.to_f) * 100).round(2)

				department_hash["internal_total"] = @internal_total
				department_hash["external_total"] = @external_total
				department_hash["internal_percent"] = @internal_percent.nan? ? 0 : @internal_percent.to_s + "%"
				department_hash["external_percent"] =  @external_percent.nan? ? 0 : @external_percent.to_s + "%"

				@buckets.each do |b|
					department_hash["internal_#{b.name}"] =  @internal.where(bucket_id: b.id).count
					department_hash["external_#{b.name}"] =  @external.where(bucket_id: b.id).count
				end

				budget_data_hash[d.name] = department_hash
			end
			return budget_data_hash
		end

	end
end