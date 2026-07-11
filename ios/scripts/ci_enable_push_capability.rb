#!/usr/bin/env ruby
# Enable Push Notifications capability on an App ID via App Store Connect API.
require 'jwt'
require 'json'
require 'net/http'
require 'uri'
require 'openssl'

issuer = ENV.fetch('APP_STORE_CONNECT_ISSUER_ID')
kid = ENV.fetch('APP_STORE_CONNECT_API_KEY_ID')
key_content = ENV.fetch('APP_STORE_CONNECT_API_PRIVATE_KEY')
bundle_id = ENV.fetch('BUNDLE_ID', 'com.personalos.story-tracker')

key = OpenSSL::PKey::EC.new(key_content)
payload = { iss: issuer, iat: Time.now.to_i, exp: Time.now.to_i + 1200, aud: 'appstoreconnect-v1' }
token = JWT.encode(payload, key, 'ES256', { kid: kid })

def asc_request(method, path, token, body = nil)
  uri = URI("https://api.appstoreconnect.apple.com#{path}")
  req = case method
        when :get then Net::HTTP::Get.new(uri)
        when :post then Net::HTTP::Post.new(uri)
        else abort("unsupported method #{method}")
        end
  req['Authorization'] = "Bearer #{token}"
  req['Content-Type'] = 'application/json'
  req.body = JSON.generate(body) if body
  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |h| h.request(req) }
  parsed = res.body.to_s.empty? ? {} : JSON.parse(res.body)
  [res.code.to_i, parsed]
end

code, bundles = asc_request(:get, "/v1/bundleIds?filter[identifier]=#{URI.encode_www_form_component(bundle_id)}&limit=1", token)
abort("bundleIds lookup failed #{code}: #{bundles}") unless code == 200
bundle_rid = bundles.dig('data', 0, 'id')
abort("bundle id not found: #{bundle_id}") unless bundle_rid

code, caps = asc_request(:get, "/v1/bundleIds/#{bundle_rid}/bundleIdCapabilities", token)
abort("bundleIdCapabilities list failed #{code}: #{caps}") unless code == 200

if caps['data']&.any? { |cap| cap.dig('attributes', 'capabilityType') == 'PUSH_NOTIFICATIONS' }
  puts "Push Notifications already enabled for #{bundle_id}"
  exit 0
end

body = {
  data: {
    type: 'bundleIdCapabilities',
    attributes: { capabilityType: 'PUSH_NOTIFICATIONS' },
    relationships: {
      bundleId: { data: { type: 'bundleIds', id: bundle_rid } }
    }
  }
}

code, created = asc_request(:post, '/v1/bundleIdCapabilities', token, body)
if code == 201
  puts "Enabled Push Notifications for #{bundle_id}"
  exit 0
elsif code == 409
  puts "Push Notifications already enabled for #{bundle_id} (409)"
  exit 0
else
  abort("enable PUSH_NOTIFICATIONS failed #{code}: #{created}")
end
