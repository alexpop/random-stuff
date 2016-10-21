# encoding: utf-8
### Sample script to auth, list nodes, environments in Chef Compliance using the API
### Change the 'api_url', 'api_user', 'api_pass' and 'api_org' variables below
### Chef Compliance API docs: https://docs.chef.io/api_compliance.html

require 'json'
require 'uri'
require 'net/http'
require 'openssl'

def api_call(method, uri, body = nil)
  uri = "/api" + uri
  case method.upcase
  when "GET"
    request = Net::HTTP::Get.new(uri)
  when "POST"
    request = Net::HTTP::Post.new(uri)
  when "PATCH"
    request = Net::HTTP::Patch.new(uri)
  when "DELETE"
    request = Net::HTTP::Delete.new(uri)
  else
    puts "*** Invalid method #{method} for api_call"
    exit 1
  end
  # Post the nodes to the Compliance Server
  request.add_field('Content-Type', 'application/json')
  request.add_field('Authorization', "Bearer #{@api_token}") unless @api_token.nil?
  request.body = body unless body.nil?
  response = @http.request(request)
  if response.code != '200'
    puts "*** Failed #{method} to #{uri}, reason: #{response.body} code: #{response.code}"
    exit 2
  end
  return response
end

# Change these to fit your Chef Compliance server(tested against 1.3.1, 1.6.8)
api_url = 'https://ap-cc6.opschef.tv'
api_user = 'admin'
api_pass = 'admin'
api_org = 'admin'

uri = URI.parse(api_url)
@http = Net::HTTP.new(uri.host, uri.port)
@http.use_ssl = true
@http.verify_mode = OpenSSL::SSL::VERIFY_NONE

response = api_call('POST', '/login', { 'userid' => api_user, 'password' => api_pass }.to_json)
@api_token = response.body

response = api_call('GET', "/owners/#{api_org}/envs")
envs = JSON.parse(response.body)

puts " * Environments:"
envs.each { |e|
  puts "   * #{e['name']} (id: #{e['id']})"
  response = api_call('GET', "/owners/#{api_org}/envs/#{e['id']}/nodes")
  nodes = JSON.parse(response.body)
  envs.each { |n|
    puts "     - #{n['name']} (id: #{n['id']}) (lastScan: #{n['lastScan']})"
  }
}
