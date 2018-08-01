#!/usr/bin/env ruby
require 'net/http'
require 'json'

def no_credentials
  puts 'Environment variables `USERNAME` and `PASSWORD` have to be defined in conjunction'
  exit
end

def no_registry_host
  puts 'A registry host must be present via `REGISTRY_HOST` environment variable'
  exit
end

def no_repository_name
  puts 'A repository name must be present via `REPOSITORY_NAME` environment variable'
  exit
end

def no_tag_prefix
  puts 'Please provide a tag prefix to look for via `TAG_PREFIX` environment variable'
  exit
end

registry_host = ENV['REGISTRY_HOST'] || no_registry_host
repository_name = ENV['REPOSITORY_NAME'] || no_repository_name
tag_prefix = ENV['TAG_PREFIX'] || no_tag_prefix
username = ENV['USERNAME']
password = ENV['PASSWORD']

if !URI.parse(registry_host).instance_of? URI::HTTPS
  registry_host = "https://#{registry_host}"
end

if (username && password.nil?) || (username.nil? && password)
  no_credentials
end

keep_versions = ENV['KEEP_VERSIONS'].to_i || 10
ignore_list = ENV['IGNORE_TAGS'] || ''
ignore_list = ignore_list.split(',')

base_uri = URI.parse "#{registry_host}/v2/#{repository_name}"

# get tag list
tags_uri = URI.parse "#{base_uri}/tags/list"
use_ssl = tags_uri.scheme == 'https'

tags_request = Net::HTTP::Get.new(tags_uri)
tags_request.basic_auth username, password

tags_response = Net::HTTP.start(
  tags_uri.host,
  tags_uri.port,
  use_ssl: use_ssl
) do |http|
  http.request(tags_request)
end

tags = JSON.parse(tags_response.body)['tags']
filtered_tags = tags - ignore_list
sorted_tags = filtered_tags.sort_by do |tag|
  build_number = tag
    .sub(tag_prefix, '') # trim defined prefix
    .match(/\d*/)        # get build number
    .to_s                # `match` returns MatchData, ensure string
    .rjust(5, '0')       # zero-fill build number
end

# get digests for older manifests
tag_map = sorted_tags.map do |tag|
  manifests_uri = URI.parse "#{base_uri}/manifests/#{tag}"

  manifests_request = Net::HTTP::Get.new(manifests_uri)
  manifests_request.basic_auth username, password
  manifests_request['Accept'] = 'application/vnd.docker.distribution.manifest.v2+json'

  manifests_response = Net::HTTP.start(
    manifests_uri.host,
    manifests_uri.port,
    use_ssl: use_ssl
  ) do |http|
    http.request(manifests_request)
  end

  {
    tag: tag,
    digest: manifests_response['docker-content-digest']
  }
end
uniquified_digests = tag_map.uniq {|tag| tag[:digest]}
uniquified_digests.pop(keep_versions)

# delete older manifests
uniquified_digests.map do |tag|
  delete_uri = URI.parse "#{base_uri}/manifests/#{tag[:digest]}"

  delete_request = Net::HTTP::Delete.new(delete_uri)
  delete_request.basic_auth username, password

  Net::HTTP.start(
    delete_uri.host,
    delete_uri.port,
    use_ssl: use_ssl
  ) do |http|
    http.request(delete_request)
  end
end

puts "Marked #{uniquified_digests.length} tags for deletion"
