#!/usr/bin/env ruby
require 'bundler/setup'
require 'rest-client'
require 'json'

class XueqiuEngine
  attr_accessor :token

  def token
    return @token if @token != nil
    begin
      response = RestClient.post 'https://xueqiu.com/provider/oauth/token',
                                              'client_id' => 'WiCimxpj5H',
                                              'client_secret' => 'TM69Da3uPkFzIdxpTEm6hp',
                                              'grant_type' => 'password'
      case response.code
      when 200
        json = JSON.parse response
        @token = json['access_token']
      end
    rescue => e
      puts "Get token failed: #{e.inspect}"
    end
  end
  
  MAX_PAGE_COUNT = 50.0
  def fetch_cube(cube_id)
    totalCount = 0
    begin
      response = RestClient.get 'https://api.xueqiu.com/cubes/rebalancing/history.json',
                  {:params => {
                  'access_token' => self.token,
                  'cube_symbol' => cube_id,
                  'count' => 1}}
                  
      puts "Get sample #{response.code}"
      case response.code
      when 200
        json = JSON.parse response
        totalCount = json['totalCount']
      end
    rescue => e
      puts "Get sample failed: #{e.inspect}"
    end
    
    pageCount = (totalCount/MAX_PAGE_COUNT).ceil
    puts "total #{totalCount} in pages #{pageCount}"
    
    actions = Array.new
    (1..pageCount).each do |page|
      begin
        response = RestClient.get 'https://api.xueqiu.com/cubes/rebalancing/history.json',
                    {:params => {
                    'access_token' => self.token,
                    'cube_symbol' => cube_id,
                    'count' => 50,
                    'page' => page}}

        puts "Get cube #{response.code} of page #{page}"
        case response.code
        when 200
          json = JSON.parse response
          json['list'].each {|list| actions.push list}
        end
      rescue => e
        puts "Get cube failed: #{e.inspect}"
      end
    end
    
    puts "Get actions: #{actions.count}"
    actions
  end
  

  def print (list)
    list.reverse.each do |action|
      puts "#{action}"
    end
  end
  
end

