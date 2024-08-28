# frozen_string_literal: true

module Availability
  class Available < Availability::Base
    def status
      if @item.item_data["requested"] == true
        "Available (Pending Request)"
      else
        "Available"
      end
    end

    def icon
      "check"
    end
  end
end
