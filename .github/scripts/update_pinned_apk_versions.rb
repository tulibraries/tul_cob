#!/usr/bin/env ruby
# frozen_string_literal: true

require "open3"
require "shellwords"

DOCKERFILE_PATH = ENV.fetch("DOCKERFILE_PATH", ".docker/app/Dockerfile")
BASE_IMAGE = ENV.fetch("APK_CHECK_BASE_IMAGE", "ruby:4.0-alpine")
SUMMARY_PATH = ENV["APK_UPDATE_SUMMARY_PATH"]

def read_dockerfile
  File.read(DOCKERFILE_PATH)
end

def arg_defaults(contents)
  contents.each_line.each_with_object({}) do |line, defaults|
    match = line.match(/\A\s*ARG\s+([A-Za-z_][A-Za-z0-9_]*)=(?:"([^"]*)"|'([^']*)'|([^\s#]+))\s*(?:#.*)?\z/)
    next unless match

    defaults[match[1]] = match[2] || match[3] || match[4]
  end
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

def resolved_pinned_packages(packages, defaults)
  packages.each_with_object({}) do |(name, version), resolved|
    match = version.match(/\A\$\{([A-Za-z_][A-Za-z0-9_]*)\}\z/)
    if match
      arg_name = match[1]
      current = defaults[arg_name]
      raise "No default value found for APK version ARG=#{arg_name}" unless current

      resolved[name] = { version: current, arg_name: arg_name }
    else
      resolved[name] = { version: version, arg_name: nil }
    end
  end
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
  current_versions.group_by { |_name, current| current[:arg_name] }.each do |arg_name, arg_packages|
    next unless arg_name

    latest_versions = arg_packages.map { |name, _current| available_versions.fetch(name) }.uniq
    if latest_versions.size > 1
      raise "APK packages using ARG=#{arg_name} have different latest versions: #{latest_versions.join(', ')}"
    end
  end

  updates = current_versions.each_with_object({}) do |(name, current), memo|
    latest = available_versions[name]
    memo[name] = {
      current: current[:version],
      latest: latest,
      arg_name: current[:arg_name]
    } if latest && latest != current[:version]
  end

  updated_contents = updates.reduce(contents) do |result, (name, update)|
    next result if update[:arg_name]

    result.gsub(
      /\b#{Regexp.escape(name)}=#{Regexp.escape(update[:current])}\b/,
      "#{name}=#{update[:latest]}"
    )
  end

  updates.values.select { |update| update[:arg_name] }.group_by { |update| update[:arg_name] }.each do |arg_name, arg_updates|
    current = arg_updates.first[:current]
    updated_contents = replace_arg_default(updated_contents, arg_name, current, arg_updates.first[:latest])
  end

  [updated_contents, updates]
end

def replace_arg_default(contents, arg_name, current, latest)
  pattern = /\A([ \t]*ARG[ \t]+#{Regexp.escape(arg_name)}=)(["']?)#{Regexp.escape(current)}\2([ \t]*(?:#.*)?\r?\n?)\z/
  replacements = 0

  updated_contents = contents.each_line.map do |line|
    match = line.match(pattern)
    if match
      replacements += 1
      "#{match[1]}#{match[2]}#{latest}#{match[2]}#{match[3]}"
    else
      line
    end
  end.join

  raise "Unable to update default value for APK version ARG=#{arg_name}" unless replacements == 1

  updated_contents
end

def write_summary(updates)
  return unless SUMMARY_PATH

  body =
    if updates.empty?
      "No APK package pin updates are available.\n"
    else
      lines = updates.sort.map do |name, update|
        "- `#{name}`: `#{update[:current]}` -> `#{update[:latest]}`"
      end
      ["Updated APK package pins in `#{DOCKERFILE_PATH}`:", *lines].join("\n") + "\n"
    end

  File.write(SUMMARY_PATH, body)
end

contents = read_dockerfile
current_versions = resolved_pinned_packages(pinned_packages(contents), arg_defaults(contents))
available_versions = latest_versions(current_versions.keys)
updated_contents, updates = apply_updates(contents, current_versions, available_versions)

if updated_contents != contents
  File.write(DOCKERFILE_PATH, updated_contents)
end

write_summary(updates)

puts(updates.empty? ? "No pinned APK updates available." : "Updated #{updates.size} pinned APK packages.")
