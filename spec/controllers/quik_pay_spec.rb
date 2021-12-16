# frozen_string_literal: true

require "rails_helper"

RSpec.describe UsersController, type: "controller"  do

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
        expect(controller.quik_pay_url).to match(/quikpay.*?orderType=Temple%20Library&timeStamp=.*&redirectUrl=.*&redirectUrlParameters=.*&hash=.*$/)
      end
    end

    context "with param as args" do
      it "generates a url with params + default params" do
        expect(controller.quik_pay_url(foo: "bar")).to match(/quikpay.*?foo=bar&orderType=Temple%20Library&timeStamp=.*&redirectUrl=.*&redirectUrlParameters=.*&hash=.*$/)
      end
    end

    context "with param as args + secret" do
      it "generates a url with params + default params" do
        expect(controller.quik_pay_url({ foo: "bar" }, "buzz")).to match(/quikpay.*?foo=bar&orderType=Temple%20Library&timeStamp=.*&redirectUrl=.*&redirectUrlParameters=.*&hash=.*$/)
      end
    end
  end

  describe "GET #quik_pay_callback" do
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
        DatabaseCleaner.clean
        DatabaseCleaner.strategy = :truncation
        user = FactoryBot.create(:user)
        sign_in user, scope: :user
      end

      it "redirects to users account paths" do
        get :quik_pay_callback
        expect(response).to redirect_to users_account_path
      end

      context "transActionStatus = 1 and no error happened"  do
        it "sets flash info" do
          resp = OpenStruct.new(total_sum: 0.0)
          balance = Alma::PaymentResponse.new(resp)
          allow(Alma::User).to receive(:send_payment) { balance }
          get :quik_pay_callback, params: { transActionStatus: "1" }
          expect(response).to redirect_to users_account_path
          expect(flash[:info]).to eq("Your balance has been paid.");
        end
      end

      context "transActionStatus = 1 and something went wrong"  do
        it "sets flash error" do
          resp = OpenStruct.new(total_sum: 0.1)
          balance = Alma::PaymentResponse.new(resp)
          allow(Alma::User).to receive(:send_payment) { balance }
          get :quik_pay_callback, params: { transActionStatus: "1" }
          expect(response).to redirect_to users_account_path
          expect(flash[:error]).to eq("There was a problem processing your payment. Please contact the library for assistance.");
        end
      end

      context "transActionStatus = 2" do
        it "sets flash error" do
          get :quik_pay_callback, params: { transActionStatus: "2" }
          expect(response).to redirect_to users_account_path
          expect(flash[:error]).to eq("Rejected credit card payment/refund (declined)");
        end
      end

      context "transActionStatus = 3" do
        it "sets flash error" do
          get :quik_pay_callback, params: { transActionStatus: "3" }
          expect(response).to redirect_to users_account_path
          expect(flash[:error]).to eq("Error credit card payment/refund (error)");
        end
      end

      context "transActionStatus = 4" do
        it "sets flash error" do
          get :quik_pay_callback, params: { transActionStatus: "4" }
          expect(response).to redirect_to users_account_path
          expect(flash[:error]).to eq("Unknown credit card payment/refund (unknown)")
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

    context "user is logged in" do
      before do
        DatabaseCleaner.clean
        DatabaseCleaner.strategy = :truncation
        user = FactoryBot.create(:user)
        sign_in user, scope: :user
      end

      it "redirects to users account paths" do
        get :quik_pay
        expect(response.location).to match(/quikpay.*?amountDue=.*&orderType=Temple%20Library&timeStamp=.*&redirectUrl=.*&redirectUrlParameters=.*&hash=.*$/)
      end
    end
  end
end
