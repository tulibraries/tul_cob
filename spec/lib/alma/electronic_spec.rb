# frozen_string_literal: true

require "rails_helper"
require "alma/electronic"

RSpec.describe Alma::Electronic do
  let(:params) { {} }
  let(:response) { Alma::Electronic.get(params) }

  describe "#get" do
    before(:each) do
      stub_request(:any, /electronic/).and_return(status: "200", body: { foo: "bar" }.to_json)
    end

    context "with :collection_id, :service_id, and :portfolio_id params" do
      let(:params) { { collection_id: "foo", service_id: "bar", portfolio_id: "buzz" } }

      it "should use the Portfolio API" do
        expect(response.class).to eq(Alma::Electronic::Portfolio)
      end

      it "generates the correct portfolio api resource" do
        resource = "/almaws/v1/electronic/e-collections/foo/e-services/bar/portfolios/buzz"
        expect(response.resource).to eq(resource)
      end

      it "is an enumerable" do
        expect(response["foo"]).to eq("bar")
      end
    end

    context "with :collection_id and  :service_id params" do
      let(:params) { { collection_id: "foo", service_id: "bar" } }

      it "should use the Service API" do
        expect(response.class).to eq(Alma::Electronic::Service)
      end

      it "generates the correct service api resource" do
        resource = "/almaws/v1/electronic/e-collections/foo/e-services/bar"
        expect(response.resource).to eq(resource)
      end
    end

    context "with :collection_id and  :type == 'servcies' param" do
      let(:params) { { collection_id: "foo", type: "services" } }

      it "should use the services API" do
        expect(response.class).to eq(Alma::Electronic::Services)
      end

      it "generates the correct services api resource" do
        resource = "/almaws/v1/electronic/e-collections/foo/e-services"
        expect(response.resource).to eq(resource)
      end
    end

    context "with only :collection_id param" do
      let(:params) { { collection_id: "foo" } }

      it "should use the Collection API" do
        expect(response.class).to eq(Alma::Electronic::Collection)
      end

      it "generates the correct collection api resource" do
        resource = "/almaws/v1/electronic/e-collections/foo"
        expect(response.resource).to eq(resource)
      end
    end

    context "with no params" do
      it "throws an error" do
        expect { response }.to raise_error(Alma::Electronic::ElectronicError)
      end
    end
  end
end
