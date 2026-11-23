# frozen_string_literal: true

require "capybara/selenium/driver"

module CapybaraChromeReset
  private
    def execute_cdp(cmd, params = {})
      super
    rescue Selenium::WebDriver::Error::InvalidArgumentError
      raise unless cmd == "Storage.clearDataForOrigin" && params[:origin] == "*"

      super("Network.clearBrowserCookies")
      return unless params[:storageTypes].to_s.include?("local_storage")

      visited_origins.each do |origin|
        super(cmd, origin:, storageTypes: "local_storage")
      end
    end

    def visited_origins
      execute_cdp("Page.getNavigationHistory").fetch("entries", []).filter_map { |entry| origin_of(entry["url"]) }.uniq
    end

    def origin_of(url)
      uri = URI.parse(url.to_s)
      "#{uri.scheme}://#{uri.host}:#{uri.port}" if %w[http https].include?(uri.scheme) && uri.host
    rescue URI::InvalidURIError
      nil
    end
end

Capybara::Selenium::Driver::ChromeDriver.prepend(CapybaraChromeReset)
