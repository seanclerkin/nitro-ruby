#!/usr/bin/env ruby
require 'rubygems'
require 'rest-client'
require 'json'
require 'getoptlong'

opts = GetoptLong.new(
  [ '--help', GetoptLong::NO_ARGUMENT ],
  [ '--nshost', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--nsuser', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--nspassword', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--resource_type', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--resource', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--action', GetoptLong::REQUIRED_ARGUMENT ],
)

nshost = nil
nsuser = nil
nspassword = nil
resource_type = nil
resource = nil
action = nil

unless ARGV.count > 0
  puts "Usage: nitro-ruby.rb --nshost <netscaler_ip> --nsuser <netscaler_username> --nspassword <netscaler_password> --resource_type (server|service) --resource <resource_name> --action (enable|disable|list)"
  exit 1
end

opts.each do |opt, arg|
  case opt
  when '--help'
      puts "Usage: nitro-ruby.rb --nshost <netscaler_ip> --nsuser <netscaler_username> --nspassword <netscaler_password> --resource_type (server|service) --resource <resource_name> --action (enable|disable|list)"
      exit 0
    when '--nshost'
      nshost = arg
    when '--nsuser'
      nsuser = arg
    when '--nspassword'
      nspassword = arg
    when '--resource_type'
      resource_type = arg
      resource_types = ['server','service']
      unless resource_types.include? resource_type
        puts "Error: accepted resource types: " + resource_types.join(",")
        exit 1
      end
    when '--resource'
      resource = arg
    when '--action'
      action = arg
      actions = ['enable', 'disable', 'list']
      unless actions.include? action
        puts "Error: accepted actions " + actions.join(",")
        exit 1
      end
  end
end



def instruct_netscaler(nshost, nsuser, nspassword, resource_type, resource, action)
  payload_hash = Hash.new
  payload_hash["name"] = resource
  payload_json = { resource_type => payload_hash}.to_json
  begin
    request = RestClient::Request.new(
      :method => "post",
      :url => "http://#{nshost}/nitro/v1/config/#{resource_type}?action=#{action}",
      :user => nsuser,
      :password => nspassword,
      :headers => { :content_type => "application/vnd.com.citrix.netscaler.#{resource_type}+json", :accept => :json },
      :payload => payload_json
      ).execute
  rescue RestClient::ResourceNotFound 
      puts "Resource #{resource} not found in Netscaler"
  rescue RestClient::Unauthorized 
      puts "Netscaler refused credentials"
  rescue SocketError 
      puts "Couldn't connect to Netscaler at #{nshost}"
  end
end

def query_netscaler(nshost, nsuser, nspassword, resource_type, resource)
  begin
    response = RestClient::Request.new(
      :method => "get",
      :url => "http://#{nshost}/nitro/v1/config/#{resource_type}/#{resource}",
      :user => nsuser,
      :password => nspassword,
      :headers => { :content_type => "application/vnd.com.citrix.netscaler.#{resource_type}+json", :accept => :json },
      ).execute
    parsed_response = JSON.parse(response)
    if resource_type == "server"
      state_element = "state"
    elsif resource_type == "service"
      state_element = "svrstate"
    end
    state = parsed_response[resource_type][0][state_element]
    puts "#{state}" 
    rescue RestClient::ResourceNotFound 
      puts "Resource #{resource} not found in Netscaler"
    rescue RestClient::Unauthorized 
      puts "Netscaler refused credentials"
    rescue SocketError 
      puts "Couldn't connect to Netscaler at #{nshost}"
  end
end
if action == "enable" or action == "disable"
  instruct_netscaler(nshost, nsuser, nspassword, resource_type, resource, action)
end
sleep 3
query_netscaler(nshost, nsuser, nspassword, resource_type, resource)