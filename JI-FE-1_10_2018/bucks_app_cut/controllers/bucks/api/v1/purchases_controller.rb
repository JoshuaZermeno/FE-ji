require 'transaction_methods'

module Bucks
	class Api::V1::PurchasesController < Bucks::Api::V1::BaseController
	  include TransactionMethods

		before_filter :authenticate_user

	  def not_found
	    head status: 404
	  end

	  def index
	  	@purchases = Purchase.where(employee_id: params[:id]).where(returned: false).group(:prize_id)
	  	render json: @purchases, each_serializer: Api::V1::PurchaseSerializer
	  end
	  
		def show
			@purchase = Purchase.find(params[:id])
			render(json: Api::V1::PurchaseSerializer.new(@purchase).to_json)
		end

	  # Inefficient repetition of code. Find a more efficient way to handle
	  # purchases in the future. For now, it just needs to be done.
	  def complete

	    @employee = ::Employee.find_by(IDnum: params[:employee_IDnum].to_i)
	    @prize_subcat = PrizeSubcat.find(params[:id])
	    @prize = Prize.find(@prize_subcat.prize_id)
	    quantity = params[:quantity].to_i
	    date = params[:date_of_use]
	    valid_purchase = true
	    

	    if @employee.get_bucks_balance < ( @prize_subcat.price * quantity )
	      @prize.errors.add(:price, "Not enough bucks!")
	      valid_purchase = false
	    end

	    if @prize.property_id != @employee.property_id
	      @prize.errors.add(:employee, "Wrong property!")
	      valid_purchase = false
	    end

	    if !@prize.must_order
	      if quantity > @prize_subcat.stock
	        @prize.errors.add(:quantity, "Not enough in stock to purchase that quantity.")
	        valid_purchase = false
	      end
	    end

	    if !@prize.limit.nil?
	      if quantity > @prize.limit
	        @prize.errors.add(:limit, @prize.limit.to_s + " per person!")
	        valid_purchase = false
	      end

	      if quantity + @employee.purchase_count(@prize) > @prize.limit
	        @prize.errors.add(:limit, "Limit reached!")
	        valid_purchase = false
	      end
	    end

	    if valid_purchase
	      quantity.times do
	        purchase = request_order(@prize, @prize_subcat, @employee, @employee)
	        perform_bucks_purchase_transaction(@prize, purchase, @employee, @employee, "Android Store")
	      end
	      Mailer.order_notify(@prize, @prize_subcat, @employee, quantity, date).deliver_now
	      msg = { :status => "Success", :message => "Prize ordered!" }
	      render json: msg, status: 201
	    else
	      render json: @prize.errors.messages, status: 500
	    end
	  end

	end
end