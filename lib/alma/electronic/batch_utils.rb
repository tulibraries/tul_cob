#!/usr/bin/env ruby
# frozen_string_literal: true

require "alma/electronic"

# Contains batch processing utils for Alma Electronic APIs.
#
# This class and its methods are used to iterate over Alma Electronic IDs to
# process and fetch Alma electronic objects via the Alma Electronic APIs.  The
# https calls are logged and can be used to rerun the batch process without
# making any further http calls or to just rerun parts of the full batch.
module Alma
  class Electronic::BatchUtils
    attr_reader :notes, :type

    # @param [Hash] options The options to create a batch instance.
    # @option [true, false] :chain true indicates a new instance of self returned.
    # @option [Array<String>] :ids List of collection ids.
    # @option ["collection", "service", "portfolio"] :type The Alma Electronic object type.
    # @option [String] :tag  A string used to tag the batch session.
    # @option [Logger] :logger A logger used t
    def initialize(options = {})
      options ||= options {}
      @chain = options.fetch(:chain, false)
      @ids = options.fetch(:ids, [])
      @type = options.fetch(:type, "collection")
      @tag = options.fetch(:tag, Time.now.to_s)
      @@logger = options.fetch(:logger, Logger.new("#{Rails.root}/log/electronic_batch_process.log"))
    end

    def get_collection_notes(ids = nil, options = {})
      ids ||= @ids
      get_notes(options.merge(ids: make_collection_ids(ids), type: "collection"))
    end

    def get_service_notes(ids = nil, options = {})
      ids ||= @ids
      get_notes(options.merge(ids: get_service_ids(ids, options), type: "service"))
    end

    def get_portfolio_notes(ids = nil, options = {})
      ids ||= @ids
      get_notes(options.merge(ids: get_portfolio_ids(ids, options, type: "portfolio")))
    end

    def get_notes(options = {})
      options ||= {}
      chain = options.fetch(:chain, @chain)
      ids = options[:ids] || (chain ? build_ids(options) : @ids)
      type = options.fetch(:type, @type)
      tag = options.fetch(:tag, @tag)
      @notes = ids.inject({}) do |notes, params|
        id = get_id(type, params)
        start = Time.now

        begin
          item = Alma::Electronic.get(params)
        rescue StandardError => e
          item = { "error" => e.message }
        end

        log(params
          .merge(type: type, start: start, tag: tag)
          .merge(item.slice("authentication_note", "public_note", "error")))

        if item.slice("authentication_note", "public_note").values.any?(&:present?)
          notes[id] = item.slice("authentication_note", "public_note")
          notes
        else
          notes
        end
      end
      self.class.new(tag: tag, chain: true)
    end

    def get_service_ids(ids = @ids, options = {})
      tag = options.fetch(:tag, @tag)
      start = Time.now

      make_collection_ids(ids)
        .map { |id| id.merge(type: "services") }
        .inject([]) do |service_ids, params|
        params.merge!(tag: tag)

        begin
          item = Alma::Electronic.get(params)

          if item["errorList"]
            log params.merge(item["errorList"])
              .merge(start: start)
          else
            item["electronic_service"].each { |service|
              service_id = { service_id: service["id"].to_s }
              service_ids << params.slice(:collection_id)
                .merge(service_id)

              log params.merge(service_id)
                .merge(start: start)
            }
          end

        rescue StandardError => e
          log params.merge("error" => e.message)
            .merge(start: start)
        end

        service_ids
      end
    end

    # Builds the notes object using the logs.
    def build_notes(options = {})
      options ||= {}
      type ||= options.fetch(:type, "collection")

      get_logged_items(options)
        .select { |item| item.slice("authentication_note", "public_note").values.any?(&:present?) }
        .inject({}) do |nodes, item|

        id = item["#{type}_id"]
        nodes.merge(id => item.slice("authentication_note", "public_note"))
      end
    end

    # Builds list of ids from logs based on failed attempts.
    # Useful for rebuilding part of collection.
    def build_failed_ids(options = {})
      successful_ids = build_successful_ids(options)
      get_logged_items(options)
        .select { |item| item.slice("authentication_note", "public_note").values.all?(&:nil?) }
        .map { |item| item["collection_id"] }
        .select { |id| !successful_ids.include? id }
        .uniq
    end

    # Builds list of ids from logs based on successful attempts.
    # Useful for verifying that failed ids have always failed.
    def build_successful_ids(options = {})
      get_logged_items(options)
        .select { |item| item.slice("authentication_note", "public_note").values.present? }
        .map { |item| item["collection_id"] }
        .uniq
    end

    # Builds a list of all ids for a specific session.
    # Useful for analytics purpose or rebuilds.
    def build_ids(options = {})
      build_failed_ids(options) + build_successful_ids(options)
    end

    def print_notes(options = {})
      options ||= {}
      chain = options.fetch(:chain, @chain)
      notes = options[:notes] || chain ? build_notes(options) : @notes
      type = options.fetch(:type, @type)
      tag = options.fetch(:tag, @tag)

      filename = options.fetch(:filename, "spec/fixtures/#{type}_notes.json")

      File.open(filename, "w") do |file|
        file.write(JSON.pretty_generate(notes))
      end
      self.class.new(tag: tag, chain: true)
    end

  private
    def log(params)
      LogUtils.json_request_logger(@@logger, params)
    end

    def get_id(type, params = {})
      id = "#{type}_id".to_sym
      params[id]
    end

    def make_collection_ids(ids = @ids)
      ids.map { |id|
        id.class == Hash ? id : { collection_id: id.to_s }
      }
    end

    # Returns JSON parsed list of logged items
    def get_logged_items(options = {})
      options ||= {}
      type ||= options.fetch(:type, "collection")
      tag ||= options.fetch(:tag, @tag)
      filename = (@@logger.instance_variable_get :@logdev).filename
      File.readlines(filename)
        .map { |log| log.match(/{.*}/).to_s }
        .select(&:present?)
        .map { |json| JSON.parse(json) }
        .select { |item| item["tag"] == tag }
        .select { |item| item["type"] == type }
    end
  end
end
