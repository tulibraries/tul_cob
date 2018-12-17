#!/usr/bin/env ruby
# frozen_string_literal: true

#
# A script for retrieving a local repository of public and authentication notes
# for electronic collections and services.
#

require File.expand_path("../../config/environment",  __FILE__)
require "alma/electronic/batch_utils"

filename = "spec/fixtures/electronic-collections-ids.csv"

ids = File.readlines(filename)
  .map(&:to_i).select(&:nonzero?)
  .map { |id| { collection_id: id.to_s } }

batch = Alma::Electronic::BatchUtils.new(ids: ids)

batch.get_collection_notes
  .get_collection_notes(ids: batch.build_failed_ids(type: "collection"))
  .print_notes

batch.get_service_notes
  .get_service_notes(ids: batch.build_failed_ids(type: "service"))
  .print_notes(type: "service")
