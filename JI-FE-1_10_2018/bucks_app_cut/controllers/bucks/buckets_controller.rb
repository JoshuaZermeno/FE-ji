module Bucks
	class BucketsController < Bucks::ApplicationController
		
		before_filter :authenticate_user_logged_in

		def create
			@bucket = Bucket.new(buckets_params)
			if @bucket.save
				@bucket.update_attribute(:property_id, session[:property])
				flash[:title] = 'Success'
				flash[:notice] = 'Bucket has successfully been created.'
				redirect_to controller: :buckets, action: :index
			else
				flash.now[:title] = 'Error'
				flash.now[:notice] = @bucket.errors.messages
				render controller: :buckets, action: :new
			end
		end

		def delete
			@bucket = Bucket.find(params[:id])
			if Buck.where(bucket_id: @bucket.id).blank?
				@bucket.destroy
				flash[:title] = 'Success'
				flash[:notice] = 'Bucket has been deleted.'
				redirect_to controller: :buckets, action: :index
			else
				flash[:title] = 'Error'
				flash[:notice] = { 'Errors' => ['One or more bucks have been issued under this bucket, and therefore cannot be deleted.']}
				redirect_to controller: :buckets, action: :edit, id: @bucket.id
			end
		end

		def edit
			if @current_user.has_admin_access
				@bucket = Bucket.find(params[:id])
				if @bucket.property_id == session[:property].to_i
					@buckets = Bucket.where(property_id: session[:property]).order(:name)
				else
					flash[:title] = 'Error'
					flash[:notice] = 'Bucket is not registered with this property.'
					redirect_to controller: :buckets, action: :index
				end
			else 
				flash[:title] = 'Error'
				flash[:notice] = 'You do not have permission to edit buckets.'
				redirect_to controller: :employees, action: 'show', id: @current_user.id
			end
		end

		def index
			if @current_user.has_admin_access
				@buckets = Bucket.where(property_id: session[:property]).order(:name)
			else 
				flash[:title] = 'Error'
				flash[:notice] = 'You do not have permission to view buckets.'
				redirect_to controller: :employees, action: 'show', id: @current_user.id
			end
		end

		def new
			if @current_user.has_admin_access
				@buckets = Bucket.where(property_id: session[:property]).order(:name)
			else 
				flash[:title] = 'Error'
				flash[:notice] = 'You do not have permission to view buckets.'
				redirect_to controller: :employees, action: 'show', id: @current_user.id
			end
		end

		def update
			@bucket = Bucket.find(params[:id])
			if @bucket.update_attributes(buckets_params)
				flash[:title] = 'Success'
				flash[:notice] = 'Bucket has successfully edited'
				redirect_to controller: :buckets, action: :index
			else
				flash.now[:title] = 'Error'
				flash.now[:notice] = @bucket.errors.messages
				render controller: :buckets, action: :edit
			end
		end

		private 
		def buckets_params
			params.require(:bucket).permit(:name, :value, :special, :property_id, :approval, :min, :max, :date, :reason, :rankings)
		end

	end
end