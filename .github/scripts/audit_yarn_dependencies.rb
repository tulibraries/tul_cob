#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "open3"

output, error_output, status = Open3.capture3("bundle", "exec", "yarn", "audit", "--json", "--summary")
audit_output = output + error_output
puts audit_output

summary = nil
audit_output.each_line do |line|
  begin
    message = JSON.parse(line)
    summary = message.dig("data", "vulnerabilities") if message["type"] == "auditSummary"
  rescue JSON::ParserError
  end
end

abort "No audit summary was returned" unless summary

high = summary.fetch("high", 0)
critical = summary.fetch("critical", 0)

if high.positive? || critical.positive?
  warn "High or critical JavaScript vulnerabilities found."
  exit 1
end

warn "Yarn reported advisories below the high-severity threshold." unless status.success?
