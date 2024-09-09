# frozen_string_literal: true

module Availability
  class Base
    def initialize(item)
      @item = item
    end

    def to_h
      { availability: status, icon:, non_circulating: tul_non_circulating? }
    end

    def icon
      default_icon
    end

    def default_icon
      "close-icon"
    end

    def status
      default_status
    end

    def default_status
      "Checked out or currently unavailable"
    end

    def tul_non_circulating?
      @item.non_circulating? ||
      @item.location == "reserve" ||
      @item.circulation_policy == "Bound Journal"
    end
  end
end
