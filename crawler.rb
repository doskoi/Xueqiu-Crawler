#!/usr/bin/env ruby
require 'bundler/setup'
require 'rest-client'
require 'json'
require 'fileutils'
require 'date'

class Crawler
  attr_accessor :aid
  
  FETCH_COUNT = 20
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
    File.expand_path("#{filename}.html", post_path)
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
    content.gsub!(/!custom.jpg/) {""}
    create_at = DateTime.strptime(json['created_at'].to_s, '%Q').strftime("%Y-%m-%d %H:%M:%S")
    
    quote_content = ""
    retweet = json['retweeted_status']
    if retweet
      retweet_title = json['retweeted_status']['title'].to_s
      retweet_content = json['retweeted_status']['text'].to_s
      
      quote_content = "<h3>#{retweet_title}</h3><p>#{retweet_content}</p>"
    end
    
    html_content = "<html>
<head>
	<meta http-equiv=\"Content-type\" content=\"text/html; charset=utf-8\">
	<title>#{title}</title>
</head>
<body>
	<h2>#{title}</h2>
	<p>#{content}</p>
	<blockquote style=\"border-left: 4px lightgrey solid;padding-left: 5px;margin-left: 20px;\">#{quote_content}</blockquote>
  <span>#{create_at}</span>
	<h4><p><a href=\"http://xueqiu.com/_/#{tid}\">原文链接</a></p></h4>
  </body>
</html>"
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
      File.open(filename2path(arg), 'w') do |f|
          f.write(html_content)
      end
    else
      puts "Post #{arg} cannot parese json"
    end
  end
  
=begin
  def parse(json, tid)
    html_content = make_content(json)
    
    # Parse post json
    if html_content
      puts "Save post #{tid}"
      File.open(filename2path(tid), 'w') do |f|
          f.write(html_content)
      end
    else
      puts "Post #{tid} cannot parese json"
    end
  end
=end
  
  def fetch()        
    begin
      params = {'access_token' => @access_token,
                      'count' => FETCH_COUNT,
                      'user_id' => @aid}
      if (@last_tid && @last_tid > 0)
        params['max_id'] = (@last_tid - 1).to_s
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
            grab(tid)
          end
          @last_tid = tid
        end

        return posts.count
      end
    rescue => e
      puts "Get post list failed: #{e.inspect}"
  
      refresh_token if e.response.code == 400 && JSON.parse(e.response)['error_code'] == "400016"
      
      fetch
    end
  end
  
  def party
    while fetch = FETCH_COUNT
      puts "---------------"
    end
  end
end


if ARGV.count == 1
  c = Crawler.new
  c.aid = ARGV.first
  c.party
else
  puts "Wrong argument"
end