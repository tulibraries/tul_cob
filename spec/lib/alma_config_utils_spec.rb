# frozen_string_literal: true

require "rails_helper"

RSpec.describe Alma::ConfigUtils do
  let(:subject) { Alma::ConfigUtils }

  describe "subject.filename" do
    context "default" do
      it "returns fixtures service_notes" do
        expect(subject.filename_or_default).to eq("spec/fixtures/service_notes.json")
      end
    end

    context "pass type" do
      it "returns fixtures #type_notes" do
        expect(subject.filename_or_default("collection", "spec/fixtures")).to eq("spec/fixtures/collection_notes.json")
      end
    end

    context "/tmp/service_notes.json is present" do
      before do
        File.write("/tmp/service_notes.json", "")
      end

      after do
        File.delete("/tmp/service_notes.json")
      end

      it "returns tmp filename" do
        expect(subject.filename_or_default).to eq("/tmp/service_notes.json")
      end
    end
  end
end
