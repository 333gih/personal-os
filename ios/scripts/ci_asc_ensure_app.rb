#!/usr/bin/env ruby
# Ensure App Store Connect app exists (macOS CI). Requires: gem install jwt
require 'jwt'
require 'json'
require 'net/http'
require 'uri'
require 'openssl'

issuer = ENV.fetch('ISSUER_ID')
kid = ENV.fetch('API_KEY_ID')
key_path = ENV.fetch('API_KEY_PATH')
bundle_id = ENV.fetch('BUNDLE_ID', 'com.personalos.story-tracker')

key = OpenSSL::PKey::EC.new(File.read(key_path))
payload = { iss: issuer, iat: Time.now.to_i, exp: Time.now.to_i + 1200, aud: 'appstoreconnect-v1' }
token = JWT.encode(payload, key, 'ES256', { kid: kid })

def asc_get(path, token)
  uri = URI("https://api.appstoreconnect.apple.com#{path}")
  req = Net::HTTP::Get.new(uri)
  req['Authorization'] = "Bearer #{token}"
  req['Content-Type'] = 'application/json'
  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |h| h.request(req) }
  [res.code.to_i, JSON.parse(res.body)]
end

def asc_post(path, token, body)
  uri = URI("https://api.appstoreconnect.apple.com#{path}")
  req = Net::HTTP::Post.new(uri)
  req['Authorization'] = "Bearer #{token}"
  req['Content-Type'] = 'application/json'
  req.body = JSON.generate(body)
  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |h| h.request(req) }
  [res.code.to_i, JSON.parse(res.body)]
end

code, apps = asc_get("/v1/apps?filter[bundleId]=#{URI.encode_www_form_component(bundle_id)}&limit=1", token)
abort("ASC list apps failed #{code}: #{apps}") unless code == 200

if apps['data']&.any?
  app = apps['data'][0]
  puts "App exists: #{app['attributes']['name']} (#{app['attributes']['bundleId']})"
  exit 0
end

code, bundles = asc_get("/v1/bundleIds?filter[identifier]=#{URI.encode_www_form_component(bundle_id)}&limit=1", token)
abort("ASC bundle lookup failed #{code}: #{bundles}") unless code == 200
bundle_rid = bundles['data'][0]['id']

body = {
  data: {
    type: 'apps',
    attributes: {
      name: 'Personal OS',
      bundleId: bundle_id,
      sku: 'personal-os-ios-001',
      primaryLocale: 'en-US'
    },
    relationships: {
      bundleId: { data: { type: 'bundleIds', id: bundle_rid } }
    }
  }
}

code, created = asc_post('/v1/apps', token, body)
if code == 201
  puts "Created app: #{created['data']['attributes']['name']}"
  exit 0
elsif code == 409
  puts 'App already exists (409)'
  exit 0
else
  abort("ASC create app failed #{code}: #{created}")
end
