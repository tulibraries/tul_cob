# frozen_string_literal: true

module Availability
  class TemporaryStatus < Availability::Base
    def status
      "Temporarily unavailable"
    end
  end
end
