# frozen_string_literal: true

module Blacklight::PrimoCentral::Response::Response
  def response
    self[:response] || {}
  end


  def total
    response.info.total
  end

  def start
    response.info.first.to_i
  end

  def empty?
    total == 0
  end
end
