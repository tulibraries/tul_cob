#!/usr/bin/env ruby
# frozen_string_literal: true

require "open3"
require "shellwords"

DOCKERFILE_PATH = ENV.fetch("DOCKERFILE_PATH", ".docker/app/Dockerfile.prod")
BASE_IMAGE = ENV.fetch("APK_CHECK_BASE_IMAGE", "ruby:3.4-alpine")
SUMMARY_PATH = ENV["APK_UPDATE_SUMMARY_PATH"]

def read_dockerfile
  File.read(DOCKERFILE_PATH)
end

def pinned_packages(contents)
  packages = {}
  in_apk_add = false

  contents.each_line do |line|
    stripped = line.strip

    in_apk_add = true if stripped.start_with?("RUN apk add ")
    if in_apk_add
      match = stripped.match(/^([a-z0-9.+_-]+)=([^\s\\]+)\s*\\?$/i)
      packages[match[1]] = match[2] if match
      in_apk_add = false unless stripped.end_with?("\\")
    end
  end

  packages
end

def parse_version_from_search_output(name, stdout)
  first_line = stdout.each_line.find { |line| !line.strip.empty? }
  raise "No apk search results returned for package=#{name}" unless first_line

  package_token = first_line.split(/\s+-\s+/, 2).first
  match = package_token.match(/-(\d[\w.]*-r\d+)$/)
  raise "Unable to parse apk version for package=#{name} from output: #{stdout.strip}" unless match

  match[1]
end

def latest_versions(package_names)
  return {} if package_names.empty?

  versions = {}

  package_names.each do |name|
    search_command = "apk update >/dev/null && apk search -x -v #{Shellwords.escape(name)}"
    command = ["docker", "run", "--rm", BASE_IMAGE, "sh", "-lc", search_command]
    stdout, stderr, status = Open3.capture3(*command)

    unless status.success?
      detail = [
        "package=#{name}",
        "status=#{status.exitstatus}",
        ("stdout=#{stdout.strip}" unless stdout.strip.empty?),
        ("stderr=#{stderr.strip}" unless stderr.strip.empty?)
      ].compact.join(", ")
      raise "Failed to query apk package version: #{detail}"
    end

    versions[name] = parse_version_from_search_output(name, stdout)
  end

  versions
end

def apply_updates(contents, current_versions, available_versions)
  updates = current_versions.each_with_object({}) do |(name, current), memo|
    latest = available_versions[name]
    memo[name] = [current, latest] if latest && latest != current
  end

  updated_contents = updates.reduce(contents) do |result, (name, (current, latest))|
    result.gsub(/\b#{Regexp.escape(name)}=#{Regexp.escape(current)}\b/, "#{name}=#{latest}")
  end

  [updated_contents, updates]
end

def write_summary(updates)
  return unless SUMMARY_PATH

  body =
    if updates.empty?
      "No APK package pin updates are available.\n"
    else
      lines = updates.sort.map { |name, (current, latest)| "- `#{name}`: `#{current}` -> `#{latest}`" }
      ["Updated APK package pins in `#{DOCKERFILE_PATH}`:", *lines].join("\n") + "\n"
    end

  File.write(SUMMARY_PATH, body)
end

contents = read_dockerfile
current_versions = pinned_packages(contents)
available_versions = latest_versions(current_versions.keys)
updated_contents, updates = apply_updates(contents, current_versions, available_versions)

if updated_contents != contents
  File.write(DOCKERFILE_PATH, updated_contents)
end

write_summary(updates)

puts(updates.empty? ? "No pinned APK updates available." : "Updated #{updates.size} pinned APK packages.")
