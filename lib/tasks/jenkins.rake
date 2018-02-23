# frozen_string_literal: true

require "time"

module Jenkins
  def self.last_build
    if ENV["JOB_URL"]
      url = "#{ENV["JOB_URL"]}lastBuild/api/json"
      user_name = ENV["JENKINS_USER_NAME"]
      api_token = ENV["JENKINS_USER_API_TOKEN"]
      auth = { username: user_name, password: api_token }
      HTTParty.get(url, verify: false, basic_auth: auth).parsed_response
    else
      {}
    end
  end

  def self.last_build_time
    job = last_build
    # Jenkins timestamps are in milliseconds.
    milliseconds_per_second = 1000
    timestamp = job["timestamp"] || 0
    Time.at(timestamp / milliseconds_per_second)
  end
end

namespace :jenkins do
  desc "Get time of the last build for jenkins job"
  task :last_build_time do
    puts Jenkins.last_build_time
  end
end
