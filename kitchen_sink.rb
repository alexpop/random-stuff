# encoding: utf-8
### Sample script to export Chef Server nodes and import them to Chef Compliance
### Change the 'api_url', 'api_user', 'api_pass' and 'api_org' variables below
### Change the nodes_array json suit your environment
### Go to your chef-repo and check Chef Server access first
# cd chef-repo; knife environment list
### Save this Ruby script as kitchen_sink.rb and run it like this:
# cat kitchen_sink.rb | knife exec
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

# This extracts data from the Chef Server. Auth done by `knife exec`
# Change loginKey and any other details that will be posted to the Chef Compliance API:
nodes_array = []
nodes.find('*:*') { |n|
  nodes_array << { id: n.name,
                   name: n.name,
                   hostname: n.name,
                   environment: n.environment,
                   loginUser: 'root',
                   loginMethod: 'ssh',
                   loginKey: 'admin/my-private-key' }
}

puts "*** Successfully exported #{nodes_array.length} nodes from the Chef Server"

# This posts data to the Chef Compliance(tested against 1.3.1)
# Change these to fit your Chef Compliance server
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

response = api_call('POST', "/owners/#{api_org}/nodes", nodes_array.to_json)

if response.code == '200'
  puts '*** Successfully imported the nodes in Chef Compliance'
else
  puts "*** Failed to import, reason: #{response.body} code: #{response.code}"
end
0
