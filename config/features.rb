# frozen_string_literal: true

Flipflop.configure do
  # Strategies will be used in the order listed here.
  strategy :cookie
  strategy :active_record
  strategy :default

  group :bento_changes do
    feature :aspace_integration
    feature :style_updates
  end

  group :citations do
    feature :citeproc_citations
  end

  group :quik_pay do
    feature :quik_pay_sessionless_callback
  end
end
