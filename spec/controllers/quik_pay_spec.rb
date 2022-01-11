# frozen_string_literal: true

require "rails_helper"

RSpec.describe UsersController, type: "controller"  do

  let(:user) { FactoryBot.create(:user) }

  describe "quik_pay_hash" do

    context "with no arguments" do
      it "returns SHA256 of empty string" do
        hash = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
        expect(controller.quik_pay_hash).to eq(hash)
      end
    end

    context "params values and no secret" do
      it "returns SHA256 of concatenated string values" do
        hash = Digest::SHA256.hexdigest "foobar"
        expect(controller.quik_pay_hash(["foo", "bar"])).to eq(hash)
      end
    end

    context "params values and secret" do
      it "returns SHA256 of concatenated string values and secret" do
        hash = Digest::SHA256.hexdigest "foobarbuzz"
        expect(controller.quik_pay_hash(["foo", "bar"], "buzz")).to eq(hash)
      end
    end

  end

  describe "quik_pay_url" do
    context "no arguments" do
      it "generates a url with only default params" do
        expect(controller.quik_pay_url).to match(/quikpay.*?orderType=Temple%20Library&timestamp=.*&redirectUrl=.*&redirectUrlParameters=.*&hash=.*$/)
      end
    end

    context "with param as args" do
      it "generates a url with params + default params" do
        expect(controller.quik_pay_url(foo: "bar")).to match(/quikpay.*?foo=bar&orderType=Temple%20Library&timestamp=.*&redirectUrl=.*&redirectUrlParameters=.*&hash=.*$/)
      end
    end

    context "with param as args + secret" do
      it "generates a url with params + default params" do
        expect(controller.quik_pay_url({ foo: "bar" }, "buzz")).to match(/quikpay.*?foo=bar&orderType=Temple%20Library&timestamp=.*&redirectUrl=.*&redirectUrlParameters=.*&hash=.*$/)
      end
    end
  end

  describe "GET #quik_pay_callback" do
    let (:params) { with_validation_params }

    context "user is not logged in" do
      it "redirects you to login page" do
        get :quik_pay_callback
        expect(response.status).to redirect_to new_user_session_path

        post :quik_pay_callback
        expect(response.status).to redirect_to new_user_session_path
      end
    end

    context "user is logged in" do
      before do
        sign_in user, scope: :user
      end

      after do
        sign_out user
      end

      it "redirects to users account paths" do
        get :quik_pay_callback, params: params
        expect(response).to redirect_to users_account_path
      end

      context "transActionStatus = 1 and no error happened"  do
        let (:params) { with_validation_params(transActionStatus: "1") }

        it "sets flash info" do
          resp = OpenStruct.new(total_sum: 0.0)
          balance = Alma::PaymentResponse.new(resp)
          allow(Alma::User).to receive(:send_payment) { balance }
          get :quik_pay_callback, params: params
          expect(response).to redirect_to users_account_path
          expect(flash[:info]).to eq("Your balance has been paid.");
        end
      end

      context "transActionStatus = 1 and something went wrong"  do
        let (:params) { with_validation_params(transActionStatus: "1") }

        it "sets flash error" do
          resp = OpenStruct.new(total_sum: 0.1)
          balance = Alma::PaymentResponse.new(resp)
          allow(Alma::User).to receive(:send_payment) { balance }
          get :quik_pay_callback, params:  params
          expect(response).to redirect_to users_account_path
          expect(flash[:error]).to eq("There was a problem processing your payment. Please contact the library for assistance.");
        end
      end

      context "transActionStatus = 2" do
        let (:params) { with_validation_params(transActionStatus: "2") }

        it "sets flash error" do
          get :quik_pay_callback, params: params
          expect(response).to redirect_to users_account_path
          expect(flash[:error]).to eq("Rejected credit card payment/refund (declined)");
        end
      end

      context "transActionStatus = 3" do
        let (:params) { with_validation_params(transActionStatus: "3") }

        it "sets flash error" do
          get :quik_pay_callback, params: params
          expect(response).to redirect_to users_account_path
          expect(flash[:error]).to eq("Error credit card payment/refund (error)");
        end
      end

      context "transActionStatus = 4" do
        let (:params) { with_validation_params(transActionStatus: "4") }

        it "sets flash error" do
          get :quik_pay_callback, params: params
          expect(response).to redirect_to users_account_path
          expect(flash[:error]).to eq("Unknown credit card payment/refund (unknown)")
        end
      end

      context "no hash provided" do
        let (:params) { with_validation_params.except(:hash) }

        it "should error out" do
          expect { get :quik_pay_callback, params: params }.to raise_error QuikPay::InvalidHash
        end
      end

      context "invalid hash provided" do
        # The has will be invalid because it wont account for the foo param.
        let (:params) { with_validation_params.merge("foo" => "bar") }

        it "should error out" do
          expect { get :quik_pay_callback, params: params }.to raise_error QuikPay::InvalidHash
        end
      end

      context "with invalid timestamp provided" do
        # The has will be invalid because it wont account for the foo param.
        let (:params) { with_validation_params(timestamp: 1) }

        it "should error out" do
          expect { get :quik_pay_callback, params: params }.to raise_error QuikPay::InvalidTime
        end
      end

    end
  end

  describe "GET #quik_pay" do
    context "user is not logged in" do
      it "redirects you to login page" do
        get :quik_pay
        expect(response.status).to redirect_to new_user_session_path

        post :quik_pay
        expect(response.status).to redirect_to new_user_session_path
      end
    end

    describe "user is logged in" do
      before do
        sign_in user, scope: :user
      end

      after do
        sign_out user
      end

      context "user can pay online" do
        it "redirects to users account paths" do
          session["can_pay_online?"] = true;
          get :quik_pay
          expect(response.location).to match(/quikpay.*?amountDue=.*&orderType=Temple%20Library&timestamp=.*&redirectUrl=.*&redirectUrlParameters=.*&hash=.*$/)
        end
      end

      context "user cannot pay online" do
        it "raises an exception" do
          session["can_pay_online?"] = false;
          expect { get :quik_pay }.to raise_error QuikPay::AccessDenied
        end
      end
    end
  end

  def with_validation_params(params = {})
    # Order shouldn't matter but in this test context .to_query gets
    # used somewhere and thus params are not in order of hash so we need to
    # control for that.
    params_dup = params.dup
    time_now = Time.now.getutc.to_i

    params_dup.merge!(timestamp: time_now) if params_dup[:timestamp].nil?

    hash = controller.quik_pay_hash(params_dup.sort.to_h.values, Rails.configuration.quik_pay["secret"])

    params_dup.merge(hash: hash)
  end
end
