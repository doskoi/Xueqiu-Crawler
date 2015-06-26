#!/usr/bin/env ruby
require 'bundler/setup'
require 'rest-client'
require 'json'
require 'fileutils'

class Crawler
  attr_accessor :aid
  
  ACCESS_TOKEN_PATH = File.expand_path("access_token", File.dirname(__FILE__))
  
  def initialize
    if File.exist? ACCESS_TOKEN_PATH
      @access_token = File.read ACCESS_TOKEN_PATH
    end
  end
  
  def refresh_token
    access_token_response = RestClient.post 'https://xueqiu.com/provider/oauth/token',
    'client_id' => 'WiCimxpj5H',
    'client_secret' => 'TM69Da3uPkFzIdxpTEm6hp',
    'grant_type' => 'password'

    json = JSON.parse access_token_response
    @access_token = json['access_token']
    if @access_token
      File.open(ACCESS_TOKEN_PATH, 'w') do |f|
          f.write(@access_token)
      end
    end
  end
  
  def post_path
    path = File.expand_path("posts/#{@aid}", File.dirname(__FILE__))
    FileUtils.mkdir_p path
    return path
  end
  
  def filename2path (filename)
    File.expand_path(filename.to_s, post_path)
  end
  
  def get_tid(json)
    posts = Array.new
    json['statuses'].each do |post|
      if post
        posts.push post['id']
      end
    end
  
    return posts
  end
  
  def make_content(json)
    tid = json['id'].to_s
    title = json['title'].to_s
    content = json['text'].to_s

    quote_content = ""
    retweet = json['retweeted_status']
    if retweet
      retweet_title = json['retweeted_status']['title'].to_s
      retweet_content = json['retweeted_status']['description'].to_s
      
      quote_content = "<h3>#{retweet_title}</h3><p>#{retweet_content}</p>"
    end
    
    html_content = "
    <html>
    	<h2>#{title}</h2>
    	<p>#{content}</p>
    	<blockquote style=\"border-left: 4px lightgrey solid;padding-left: 5px;margin-left: 20px;\">#{quote_content}</blockquote>
    	<h4><p><a href=\"http://xueqiu.com/_/#{tid}\">原文链接</a></p></h4>
    </html>
    "
    return html_content
  end
  
  def grab(arg)
    begin
      response = RestClient.get 'https://api.xueqiu.com/statuses/show.json',
                  {:params => {
                      'access_token' => @access_token,
                      'id' => arg}}
        
      puts "Get post #{response.code}"
      case response.code
      when 200
        json = JSON.parse response
        html_content = make_content(json)
      end
    rescue => e
      puts "Get post failed: #{e.inspect}"

      refresh_token if e.response.code == 400 && JSON.parse(e.response)['error_code'] == "400016"
    end
    
    # Parse post json
    if html_content
      puts "Save post #{arg}"
      File.open(File.expand_path("#{arg}.html", post_path), 'w') do |f|
          f.write(json)
      end
    else
      puts "Post #{arg} cannot parese json"
    end
  end
  
  def parse(json, tid)
    html_content = make_content(json)
    
    # Parse post json
    if html_content
      puts "Save post #{tid}"
      File.open(File.expand_path("#{tid}.html", post_path), 'w') do |f|
          f.write(json)
      end
    else
      puts "Post #{tid} cannot parese json"
    end
  end
  
  def fetch()        
    begin
      params = {'access_token' => @access_token,
                      'count' => 20,
                      'user_id' => @aid}
      if @last_tid
        params['max_id'] = (@last_tid.to_i - 1).to_s
      end

      response = RestClient.get 'https://xueqiu.com/v4/statuses/user_timeline.json',
                  {:params => params}
                    
      puts "Get post list #{response.code}"
      case response.code
      when 200
        rep = JSON.parse response
        posts = get_tid(rep)

        posts.each do |tid|
          # Get post json
          if File.exist?(filename2path(tid))
            puts "Post #{tid} are exist"
          else
            # not exist
            # grab(tid)
            parse(rep, tid)
          end
        end
        
        fetch if post.count > 1
      end
    rescue => e
      puts "Get post list failed: #{e.inspect}"
  
      refresh_token if e.response.code == 400 && JSON.parse(e.response)['error_code'] == "400016"
      
      fetch
    end
  end
end


if ARGV.count == 1
  c = Crawler.new
  c.aid = ARGV.first
  c.fetch
else
  puts "Wrong argument"
end