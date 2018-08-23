#!/opt/sensu/embedded/bin/ruby

require 'rubygems'
require 'net/http'
require 'logger'
require 'thread'
require 'json'
require 'optparse'


Read_timeout = 10
Semaphore_threads_num = 20
Semaphore_sleep_time = 2
$status_file = nil
$ignore_list = []

Google_keys = [ 'google_api_key']   # BIScience key

def get_location lat, lng
  uri = URI.parse("https://maps.googleapis.com/maps/api/geocode/json?latlng=#{lat},#{lng}&sensor=false&key=#{Google_keys[0]}")
  conn = Net::HTTP.new(uri.host, uri.port)
  conn.use_ssl = true

  conn.start() do |http|
    req = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(req)
    begin
      rh = JSON::load(response.body)
    rescue JSON::ParserError
      puts "Can't parse response for #{@ip}"
      rh = nil
    end

    c = ''
    if rh['error_message']
      puts "#{rh['error_message']} second call for #{@ip}"
      break
    end

    puts rh['results'].first['formatted_address']
  end
end

uri = URI.parse("https://www.googleapis.com/geolocation/v1/geolocate?key=#{Google_keys[0]}")

ip=ARGV[0]
port=ARGV[1]
proxy_user=ARGV[2]
proxy_password=ARGV[3]
#conn=Net::HTTP.new(uri.host, uri.port, ip, port)
conn=Net::HTTP.new(uri.host, uri.port, ip, port, proxy_user, proxy_password)
rh = nil
conn.use_ssl = true
conn.read_timeout = Read_timeout
conn.start() do |http|
  req = Net::HTTP::Post.new(uri.request_uri)
  response = http.request(req)
  begin
    rh = JSON::load(response.body)
  rescue JSON::ParserError
      $log.error "Can't get coordinates for #{ip}:#{port}"
      return nil, nil
  end
end

  if rh && rh['error_message']
    $log.error "ERROR: #{rh['error_message']} for #{ip}#{port}"
    return nil,nil
  end

  if rh && rh['location']
    puts rh['location']['lat']
    puts rh['location']['lng']
  else
    puts "Coordinates not found for #{ip}:#{port}"
    exit
  end

get_location(rh['location']['lat'], rh['location']['lng'])
