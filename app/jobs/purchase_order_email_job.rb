# frozen_string_literal: true

class PurchaseOrderEmailJob < ApplicationJob
  queue_as :default

  def perform(documents, details, url_gen_params)
    PurchaseOrderMailer.purchase_order(documents, details, url_gen_params).deliver
  end
end
