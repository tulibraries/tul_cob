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
  .map { |id| { collection_id: id } }

batch = Alma::Electronic::BatchProcess.new(ids: ids)

batch.get_notes(type: "collection")
  .print_notes

batch.get_notes(type: "service")
  .print_notes
