# frozen_string_literal: true

require "rails_helper"
require "alma/electronic/batch_utils"

RSpec.describe Alma::Electronic::BatchUtils do
  let(:data) { { foo: "bar" } }
  let(:ids) { [] }
  let(:type) { "collection" }
  let(:batch) { Alma::Electronic::BatchUtils.new(options) }
  let(:logfile) { "#{Rails.root}/log/electronic_batch_process_spec.log" }
  let(:logger) { Logger.new(logfile) }
  let(:options) { { ids: ids, logger: logger } }

  before do
    File.truncate(logfile, 0) if File.exist?(logfile)
    stub_request(:any, /electronic/).and_return(status: "200", body: data.to_json)
  end

  describe "#get_collection_notes" do
    before do
      batch.get_collection_notes
    end

    context "empty collection ids" do
      it "has access to empty notes" do
        expect(batch.notes).to eq({})
      end

      it "sets the type of notes" do
        expect(batch.type).to eq("collection")
      end
    end

    context "collections return notes" do
      let(:ids) { [ "foo", "bar" ] }
      let(:data) { { authentication_note: "hello world" } }

      it "collects the notes" do
        expect(batch.notes).to eq(
          "foo" => { "authentication_note" => "hello world" },
          "bar" => { "authentication_note" => "hello world" },
        )
      end
    end

    context "collections do not return notes" do
      let(:ids) { [ "foo", "bar" ] }

      it "does not collect any notes" do
        expect(batch.notes).to eq({})
      end
    end
  end

  describe "#build_notes" do
    let(:items) { [] }
    let(:options) { { ids: ids, tag: "BUZZ" } }

    before do
      allow(batch).to receive(:get_logged_items) { items }
    end

    context "empty collection ids" do
      it "has access to empty notes" do
        expect(batch.build_notes(options)).to eq({})
      end
    end

    context "logs have notes" do
      let(:ids) { [ "foo", "bar" ] }
      let(:items) { [
        { "collection_id" => "foo", "authentication_note" => "hello world" },
      ] }

      it "builds the notes" do
        expect(batch.build_notes(options)).to eq(
          "foo" => { "authentication_note" => "hello world" },
        )
      end
    end

    context "logs do not have notes" do
      let(:ids) { [ "foo", "bar" ] }

      it "builds an empty notes set" do
        expect(batch.build_notes(options)).to eq({})
      end
    end
  end

  describe "#build_failed_ids" do
    let(:items) { [] }

    before do
      allow(batch).to receive(:get_logged_items) { items }
    end

    context "with no logged items" do
      it "builds an empty list of ids" do
        expect(batch.build_failed_ids).to eq([])
      end
    end

    context "with one successful item" do
      let(:items) { [ { "collection_id" => "foo", "public_note" => "bar" } ] }

      it "builds an empty list of ids" do
        expect(batch.build_failed_ids).to eq([])
      end
    end

    context "with one failed item" do
      let(:items) { [ { "collection_id" => "foo", "error" => "bar" } ] }

      it "builds a list of empty ids" do
        expect(batch.build_failed_ids).to eq(["foo"])
      end
    end

    context "with mixed failed and passing items" do
      let(:items) { [
        { "collection_id" => "fizz", "public_note" => "buzz" },
        { "collection_id" => "foo", "error" => "bar" }
      ] }

      it "builds a list of empty ids" do
        expect(batch.build_failed_ids).to eq(["foo"])
      end
    end

    context "with duplicate failing items" do
      let(:items) { [
        { "collection_id" => "fizz", "error" => "buzz" },
        { "collection_id" => "fizz", "error" => "bar" }
      ] }

      it "builds a list of one item" do
        expect(batch.build_failed_ids).to eq(["fizz"])
      end
    end
  end

  describe "#build_successful_ids" do
    let(:items) { [] }

    before do
      allow(batch).to receive(:get_logged_items) { items }
    end

    context "with no logged items" do
      it "builds an empty list of ids" do
        expect(batch.build_successful_ids).to eq([])
      end
    end

    context "with one successful item" do
      let(:items) { [ { "collection_id" => "foo", "public_note" => "bar" } ] }

      it "builds list with one item" do
        expect(batch.build_successful_ids).to eq(["foo"])
      end
    end

    context "with one failed item" do
      let(:items) { [ { "collection_id" => "foo", "error" => "bar" } ] }

      it "builds an empty list" do
        expect(batch.build_successful_ids).to eq([])
      end
    end

    context "with mixed failed and passing items" do
      let(:items) { [
        { "collection_id" => "fizz", "public_note" => "buzz" },
        { "collection_id" => "foo", "error" => "bar" }
      ] }

      it "builds a list of one item" do
        expect(batch.build_successful_ids).to eq(["fizz"])
      end
    end

    context "with duplicate passing items" do
      let(:items) { [
        { "collection_id" => "fizz", "public_note" => "buzz" },
        { "collection_id" => "fizz", "public_note" => "bar" }
      ] }

      it "builds a list of one item" do
        expect(batch.build_successful_ids).to eq(["fizz"])
      end
    end
  end
end
