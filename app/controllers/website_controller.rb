class WebsiteController < ApplicationController

  def index
  end

  def donate
    donation = Donation.new(donation_params)

    if donation.valid? && donation.paid
      charity.credit_amount(donation.satang_amount)
      flash.notice = t(".success")
    else
      @token = retrieve_token(params[:omise_token])
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

  def retrieve_token(token)
    if Rails.env.test?
      OpenStruct.new({
        id: "tokn_X",
        card: OpenStruct.new({
          name: "J DOE",
          last_digits: "4242",
          expiration_month: 10,
          expiration_year: 2020,
          security_code_check: false,
        }),
      })
    else
      Omise::Token.retrieve(token)
    end
  end

  def donation_params
    {
      omise_token: params[:omise_token],
      amount: params[:amount].to_i,
      charity: charity
    }
  end
end
