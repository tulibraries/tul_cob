# frozen_string_literal: true

require "rails_helper"

RSpec.describe NoteHelper, type: :helper do
  describe "#get_unavailable_notes" do
    let(:service_notes) {  { "foo" => { "value" => "foo" } } }

    before do
      allow(helper).to receive(:electronic_notes).with("service") { service_notes }
    end

    context "with no unavailable notes" do
      it "should not return any unavailability notes" do
        expect(helper.get_unavailable_notes("bizz")).to eq([])
      end
    end

    context "with unavailable notes" do
      let(:service_notes) {  { "bizz" => {
        "key" => "foo",
        "service_temporarily_unavailable" => "foo",
        "service_unavailable_reason" => "bar",
        "service_unavailable_date" => "buzz",
      } } }

      it "should not return any unavailability notes" do
        expect(helper.get_unavailable_notes("bizz")).to eq(["This service is temporarily unavailable due to: bar."])
      end
    end
  end

  describe "#render_electronic_notes" do
    let(:service_notes) {  { "foo" => { "value" => "foo" } } }
    let(:collection_notes) {  { "bizz" => { "value" => "bar" } } }
    let(:public_notes) { "public note" }

    before do
      allow(helper).to receive(:render) { "rendered note" }
      allow(Rails.cache).to receive(:fetch).with("collection_notes") { collection_notes }
      allow(Rails.cache).to receive(:fetch).with("service_notes") { service_notes }
    end

    context "with no notes" do
      let(:field) { {} }

      it "should not render any notes" do
        expect(render_electronic_notes(field)).to be_nil
      end
    end

    context "with public notes" do
      let(:field) { { "public_note" => "public note" } }

      it "should render the notes" do
        expect(render_electronic_notes(field)).to eq("rendered note")
      end
    end

    context "with authentication notes" do
      let(:field) { { "authentication_note" => "authentication note" } }

      it "should render the notes" do
        expect(render_electronic_notes(field)).to eq("rendered note")
      end

      it "should parse the authenticated notes" do
        allow(helper).to receive(:render) do |arg|
          expect(arg.dig(:locals, :authentication_notes)).to eq("authentication note")
          ""
        end

        render_electronic_notes(field)
      end
    end

    context "with service notes" do
      let(:field) { { "service_id" => "foo" } }

      it "should render the notes" do
        expect(render_electronic_notes(field)).to eq("rendered note")
      end
    end

    context "with collection notes" do
      let(:field) { { "collection_id" => "bizz" } }

      it "should render the notes" do
        expect(render_electronic_notes(field)).to eq("rendered note")
      end
    end

    context "with both collection and service notes" do
      let(:field) { { "service_id" => "foo", "collection_id" => "bizz" } }

      it "should render the notes" do
        expect(render_electronic_notes(field)).to eq("rendered note")
      end
    end

    context "with unavailable notes" do
      let(:field) { { "service_id" => "buzz", "collection_id" => "bizz" } }
      let(:service_notes) { { "foo" => {
        "service_temporarily_unavailable" => "foo",
        "service_unavailable_date" => "bar",
        "service_unavailable_reason" => "buzz"
      } } }

      it "should render the notes" do
        expect(render_electronic_notes(field)).to eq("rendered note")
      end
    end
  end
end
