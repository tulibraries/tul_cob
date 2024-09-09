# frozen_string_literal: true

module Availability
  class Unavailable < Availability::Base
    require "date"

    def status
      [process_type, due_date].join("")
    end

    private

      def process_type
        Rails.configuration.process_types[@item.process_type] || default_status
      end

      def due_date
        due_date_time = @item["item_data"].fetch("due_date", nil)
        unless due_date_time.nil?
          ", due " + DateTime.iso8601(due_date_time).in_time_zone.strftime("%m/%d/%Y")
        end
      end
  end
end
