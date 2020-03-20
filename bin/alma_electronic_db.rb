#!/usr/bin/env ruby
# frozen_string_literal: true

#
# A script for retrieving a local repository of public and authentication notes
# for electronic collections and services.
#

require File.expand_path("../../config/environment",  __FILE__)
require "alma/electronic/batch_utils"

ids =  Alma::Electronic.get_ids
  .map { |id| { collection_id: id.to_s } }

batch = Alma::Electronic::BatchUtils.new(ids: ids)

batch.get_collection_notes
  .print_notes

batch.get_service_notes
  .print_notes(type: "service")
