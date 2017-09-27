require 'minitest/mock'
require 'test_helper'

class WebsiteTest < ActionDispatch::IntegrationTest
  def mock_retrieve_token
    mocked_token = OpenStruct.new({
      id: "tokn_X",
      card: OpenStruct.new({
        name: "J DOE",
        last_digits: "4242",
        expiration_month: 10,
        expiration_year: 2020,
        security_code_check: false,
      }),
    })
    Omise::Token.stub(:retrieve, mocked_token) do
      yield
    end
  end

  test "should get index" do
    get "/"
    mock_retrieve_token do
      assert_response :success
    end
  end

  test "that someone can't donate to no charity" do
    mock_retrieve_token do
      post donate_path, amount: "100", omise_token: "tokn_X", charity: ""
    end

    assert_template :index
    assert_equal t("website.donate.failure"), flash.now[:alert]
  end

  test "that someone can't donate 0 to a charity" do
    charity = charities(:children)
    mock_retrieve_token do
      post donate_path, amount: "0", omise_token: "tokn_X", charity: charity.id
    end

    assert_template :index
    assert_equal t("website.donate.failure"), flash.now[:alert]
  end

  test "that someone can't donate less than 20 to a charity" do
    charity = charities(:children)
    mock_retrieve_token do
      post donate_path, amount: "19", omise_token: "tokn_X", charity: charity.id
    end

    assert_template :index
    assert_equal t("website.donate.failure"), flash.now[:alert]
  end

  test "that someone can't donate without a token" do
    charity = charities(:children)
    mock_retrieve_token do
      post donate_path, amount: "100", charity: charity.id
    end

    assert_template :index
    assert_equal t("website.donate.failure"), flash.now[:alert]
  end

  test "that someone can donate to a charity" do
    charity = charities(:children)
    initial_total = charity.total
    expected_total = initial_total + (100 * 100)

    Omise::Charge.stub(:create, OpenStruct.new({ amount: 10000, paid: true })) do
      post_via_redirect donate_path, amount: "100", omise_token: "tokn_X", charity: charity.id
    end

    assert_template :index
    assert_equal t("website.donate.success"), flash[:notice]
    assert_equal expected_total, charity.reload.total
  end

  test "that if the charge fail from omise side it shows an error" do
    charity = charities(:children)
    Omise::Charge.stub(:create, OpenStruct.new({ amount: 10000, paid: false })) do
      mock_retrieve_token do
        post donate_path, amount: "100", omise_token: "tokn_X", charity: charity.id
      end
    end

    assert_template :index
    assert_equal t("website.donate.failure"), flash.now[:alert]
  end

  test "that we can donate to a charity at random" do
    charities = Charity.all
    initial_total = charities.to_a.sum(&:total)
    expected_total = initial_total + (100 * 100)

    Omise::Charge.stub(:create, OpenStruct.new({ amount: 10000, paid: true })) do
      post donate_path, amount: "100", omise_token: "tokn_X", charity: "random"
    end

    assert_template :index
    assert_equal expected_total, charities.to_a.map(&:reload).sum(&:total)
    assert_equal t("website.donate.success"), flash[:notice]
  end

  test "that someone can donate to a charity with satang" do
    charity = charities(:children)
    initial_total = charity.total
    expected_total = initial_total + (100.99 * 100)

    Omise::Charge.stub(:create, OpenStruct.new({ amount: 10099, paid: true })) do
      post_via_redirect donate_path, amount: "100.99", omise_token: "tokn_X", charity: charity.id
    end

    assert_template :index
    assert_equal t("website.donate.success"), flash[:notice]
    assert_equal expected_total, charity.reload.total
  end
end
