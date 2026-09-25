# frozen_string_literal: true

require "rails_helper"

RSpec.describe Alma::ConfigUtils do
  let(:subject) { Alma::ConfigUtils }

  describe ".filename" do
    context "when path is a JSON file" do
      it "returns the path unchanged" do
        expect(subject.filename("service", "/tmp/custom_notes.json")).to eq("/tmp/custom_notes.json")
      end
    end

    context "when path is a directory" do
      it "builds the notes filename from the type" do
        expect(subject.filename("collection", "/tmp")).to eq("/tmp/collection_notes.json")
      end
    end
  end

  describe ".load_notes" do
    it "parses service notes from a JSON file" do
      notes = subject.load_notes(path: subject.fixture_filename)

      expect(notes["62337184620003811"]["public_note"]).to include("clearing cookies")
    end

    it "loads notes for the requested type from a directory" do
      notes = subject.load_notes(type: "collection", path: "spec/fixtures")

      expect(notes["61369070880003811"]["public_note"]).to eq("Access electronic resource.")
    end
  end

  describe ".filename_or_default" do
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
