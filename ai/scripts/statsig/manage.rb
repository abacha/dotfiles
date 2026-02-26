#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'uri'
require 'optparse'

# Simple .env loader
def load_env(path)
  return unless File.exist?(path)
  File.foreach(path) do |line|
    next if line.start_with?('#') || line.strip.empty?
    key, value = line.strip.split('=', 2)
    ENV[key] = value if key && value
  end
end

# Load .env files
load_env(File.expand_path('~/.env'))
load_env(File.expand_path('~/projects/hubstaff/hubstaff-server/.env'))
load_env(File.expand_path('~/projects/hubstaff/hubstaff-server/spec/e2e/.env_dev'))

class StatsigManager
  BASE_URL = 'https://statsigapi.net/console/v1'

  def initialize(options)
    @options = options
    # Check STATSIG_CONSOLE_KEY (from .env_dev) or STATSIG_CONSOLE_API_KEY (standard)
    @console_key = ENV['STATSIG_CONSOLE_KEY'] || ENV['STATSIG_CONSOLE_API_KEY']
    @secret_key = ENV['STATSIG_SECRET_KEY']
  end

  def run
    case @options[:command]
    when 'list'
      list_entities
    when 'get'
      get_entity
    when 'create'
      create_entity
    when 'update'
      update_entity
    else
      puts "Unknown command. Use --help for usage."
    end
  end

  private

  def list_entities
    ensure_console_key!
    
    type = @options[:type] # experiments, dynamic_configs, layers, gates
    endpoint = case type
               when 'experiment', 'experiments' then '/experiments'
               when 'config', 'configs', 'dynamic_configs' then '/dynamic_configs'
               when 'layer', 'layers' then '/layers'
               when 'gate', 'gates', 'feature_gates' then '/gates'
               else
                 puts "Invalid type for list. Use: experiments, configs, layers, gates"
                 return
               end

    response = request(:get, endpoint)
    
    if response['message'] && !response['data']
      puts "Error: #{response['message']}"
    else
      # Handle pagination if needed, for now just dump the list
      items = response['data'] || []
      
      # Sort by creation time if available
      items.sort_by! { |i| i['createdTime'] || 0 }.reverse!

      puts "Found #{items.count} #{type} (showing enabled/active):"
      
      count = 0
      items.each do |item|
        status = item['isEnabled'] ? 'Enabled' : 'Disabled'
        created = item['createdTime'] ? Time.at(item['createdTime'] / 1000).strftime('%Y-%m-%d') : 'Unknown'
        puts "- [#{item['id']}] #{item['name']} (#{status}) - Created: #{created}"
        puts "  Desc: #{item['description']}" if item['description']
        
        count += 1
        break if count >= 5
      end
    end
  end

  def get_entity
    ensure_console_key!
    
    id = @options[:id]
    type = @options[:type]
    
    endpoint = case type
               when 'experiment' then "/experiments/#{id}"
               when 'config' then "/dynamic_configs/#{id}"
               when 'layer' then "/layers/#{id}"
               when 'gate' then "/gates/#{id}"
               else
                 puts "Invalid type. Use: experiment, config, layer, gate"
                 return
               end

    response = request(:get, endpoint)
    puts JSON.pretty_generate(response)
  end

  def create_entity
    ensure_console_key!
    
    type = @options[:type]
    name = @options[:name]
    id = @options[:id] || name.downcase.gsub(/[^a-z0-9_]/, '_')
    description = @options[:description] || "Created via CLI"
    
    payload = {
      name: name,
      id: id,
      description: description
    }

    endpoint = case type
               when 'experiment'
                 payload[:type] = 'experiment'
                 '/experiments'
               when 'config'
                 '/dynamic_configs'
               when 'gate'
                 '/gates'
               else
                 puts "Invalid type for create. Use: experiment, config, gate"
                 return
               end

    response = request(:post, endpoint, payload)
    
    if response['message']
      puts "Error creating #{type}: #{response['message']}"
      if response['errors']
        puts "Details: #{JSON.pretty_generate(response['errors'])}"
      end
    else
      puts "Successfully created #{type}: #{id}"
      puts JSON.pretty_generate(response)
    end
  end
  
  def update_entity
    ensure_console_key!

    id = @options[:id]
    type = @options[:type]
    payload_json = @options[:payload]

    unless payload_json
      puts "Error: --payload JSON is required for update."
      exit 1
    end

    begin
      payload = JSON.parse(payload_json)
    rescue JSON::ParserError
      puts "Error: Invalid JSON payload."
      exit 1
    end

    endpoint = case type
               when 'experiment' then "/experiments/#{id}"
               when 'config' then "/dynamic_configs/#{id}"
               when 'gate' then "/gates/#{id}"
               else
                 puts "Invalid type for update. Use: experiment, config, gate"
                 return
               end

    response = request(:patch, endpoint, payload)
    
    if response['message']
      puts "Error updating #{type}: #{response['message']}"
      if response['errors']
        puts "Details: #{JSON.pretty_generate(response['errors'])}"
      end
    else
      puts "Successfully updated #{type}: #{id}"
      puts JSON.pretty_generate(response)
    end
  end

  def ensure_console_key!
    unless @console_key
      puts "Error: STATSIG_CONSOLE_API_KEY is required for management operations."
      puts "Please export it in your shell or add to .env"
      puts "Note: The 'secret-' key in hubstaff-server/.env is for server evaluation only, not management."
      exit 1
    end
  end

  def request(method, path, body = nil)
    uri = URI("#{BASE_URL}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    headers = {
      'STATSIG-API-KEY' => @console_key,
      'Content-Type' => 'application/json'
    }

    req = case method
          when :get then Net::HTTP::Get.new(uri, headers)
          when :post then Net::HTTP::Post.new(uri, headers)
          when :patch then Net::HTTP::Patch.new(uri, headers)
          end

    req.body = body.to_json if body
    
    res = http.request(req)
    JSON.parse(res.body)
  rescue JSON::ParserError
    { 'message' => "Invalid JSON response: #{res.body}" }
  rescue StandardError => e
    { 'message' => "Request failed: #{e.message}" }
  end
end

# CLI Parsing
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: statsig_manager.rb [options] <command> <type> [id/name]"

  opts.on("-d", "--description DESC", "Description for creation") { |v| options[:description] = v }
  opts.on("-k", "--key KEY", "Console API Key") { |v| options[:console_key] = v }
  opts.on("-p", "--payload JSON", "JSON Payload for update") { |v| options[:payload] = v }
end.parse!

if ARGV.length < 2
  puts "Usage: ./manage.rb <command> <type> [id/name]"
  puts "Commands: list, get, create, update"
  puts "Types: experiment, config, layer, gate"
  exit 1
end

options[:command] = ARGV[0]
options[:type] = ARGV[1]
options[:id] = ARGV[2] # For get/create (as ID or Name)
options[:name] = ARGV[2] # Alias for create

manager = StatsigManager.new(options)
manager.run
