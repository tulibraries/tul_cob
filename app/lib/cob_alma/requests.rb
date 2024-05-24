# frozen_string_literal: true

module CobAlma
  module Requests
    # Still need to refactor
    def self.item_holding_ids(items_list)
      items_list
      .select { |item| item["holding_data"]["temp_location"]["value"] != "storage" }
      .collect { |item| [item["holding_data"]["holding_id"], item["item_data"]["pid"]] }.to_h
    end

    def self.second_attempt_item_holding_ids(items_list)
      item_pids = items_list.collect { |item| item["item_data"]["pid"] }
      items_list.collect { |item| [item["holding_data"]["holding_id"], item_pids.first] }.to_h
    end
  end
end
