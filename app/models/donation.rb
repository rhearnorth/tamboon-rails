class Donation
  include ActiveModel::Model
  attr_accessor :omise_token, :amount, :charity

  validates :omise_token, presence: true
  validates :charity, presence: true
  validates :amount, numericality: { greater_than_or_equal_to: 20 }

  def paid
    charge.paid
  end

  def satang_amount
    amount.to_i * 100
  end

  def charge
    @charge ||= begin
      Omise::Charge.create({
        amount: satang_amount,
        currency: "THB",
        card: omise_token,
        description: "Donation to #{charity.name} [#{charity.id}]",
      })
    end
  end
end