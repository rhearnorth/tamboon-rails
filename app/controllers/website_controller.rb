class WebsiteController < ApplicationController

  def index
  end

  def donate
    donation = Donation.new(donation_params)

    if donation.valid? && donation.paid
      charity.credit_amount(donation.satang_amount)
      flash.notice = t(".success")
    else
      @token = Omise::Token.retrieve(params[:omise_token])
      flash.now.alert = t(".failure")
    end
    render :index
  end

  private

  def charity
    @charity ||= begin
      if params[:charity] == 'random'
        Charity.order("RANDOM()").first
      else
        Charity.find_by(id: params[:charity])
      end
    end
  end

  def donation_params
    {
      omise_token: params[:omise_token],
      amount: params[:amount].to_f,
      charity: charity
    }
  end
end
