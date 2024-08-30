# frozen_string_literal: true

module Availability
  class AwaitingReshelving < Availability::Base
    def status
      "Awaiting Reshelving"
    end
  end
end
