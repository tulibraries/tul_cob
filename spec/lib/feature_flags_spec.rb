# frozen_string_literal: true

require "spec_helper"
require "rails_helper"

RSpec.describe ::FeatureFlags do
  describe "#campus_closed?" do

    let(:params_hash) { {} }
    let(:params) { ActionController::Parameters.new(params_hash) }
    let(:cc_with_param) { described_class.campus_closed?(params) }

    context "when the Rails.config.features[:campus_closed] is default value"  do
      it "returns false" do
        expect(described_class.campus_closed?).to be(false)
      end
      context "when request_params parameter is passed" do
        context "that does not include a campus_closed param" do
          it "returns false" do
            (expect(cc_with_param).to be(false))
          end
        end
        context "that includes a campus_closed param of 'true'" do
          let(:params_hash) { { campus_closed: "true" } }
          it "returns true" do
            (expect(cc_with_param).to be(true))
          end
        end
        context "that includes a campus_closed param of 'yes'" do
          let(:params_hash) { { campus_closed: "yes" } }
          it "returns true" do
            (expect(cc_with_param).to be(true))
          end
        end
        context "that includes a campus_closed param of 'false'" do
          let(:params_hash) { { campus_closed: "false" } }
          it "returns false" do
            (expect(cc_with_param).to be(false))
          end
        end
        context "that includes a campus_closed param of '0'" do
          let(:params_hash) { { campus_closed: "0" } }
          it "returns false" do
            (expect(cc_with_param).to be(true))
          end
        end
      end
    end
    context "when Rails.config.features[:campus_closed] has been set" do
      before(:each) do
        allow(Rails.configuration.features)
          .to receive(:fetch)
          .with(:campus_closed, false)
          .and_return("true")
      end

      it "returns true" do
        expect(described_class.campus_closed?).to be(true)
      end
      context "when request_params parameter is passed" do
        context "that does not include a campus_closed param" do
          it "returns true" do
            (expect(cc_with_param).to be(true))
          end
        end
        context "that includes a campus_closed param of 'true'" do
          let(:params_hash) { { campus_closed: "true" } }
          it "returns true" do
            (expect(cc_with_param).to be(true))
          end
        end
        context "that includes a campus_closed param of 'yes'" do
          let(:params_hash) { { campus_closed: "yes" } }
          it "returns true" do
            (expect(cc_with_param).to be(true))
          end
        end
        context "that includes a campus_closed param of 'false'" do
          let(:params_hash) { { campus_closed: "false" } }
          it "returns false" do
            (expect(cc_with_param).to be(false))
          end
        end
        context "that includes a campus_closed param of '0'" do
          let(:params_hash) { { campus_closed: "0" } }
          it "returns false" do
            (expect(cc_with_param).to be(true))
          end
        end
      end

    end
  end
end
