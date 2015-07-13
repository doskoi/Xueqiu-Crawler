#!/usr/bin/env ruby
require 'bundler/setup'
require 'rest-client'
require 'json'
require 'fileutils'
require_relative 'xueqiu'

class Crawler
  attr_accessor :aid, :author

  def initialize
    @xueqiu = XueqiuEngine.new
    @access_token = @xueqiu.token
  end
  
  def post_path
    path = File.expand_path("posts/#{@aid}", File.dirname(__FILE__))
    FileUtils.mkdir_p path
    return path
  end
  
  def filename2path (filename)
    File.expand_path("#{filename}.html", post_path)
  end
    
  def make_post_content(post)
    @author = post.author_screenname if !@author
    
    tid = post.id
    author_id = post.author_id
    title = post.title
    content = post.text
    created_at = post.created_at_readable
    quote_content = ""
    if post.retweet_text
      retweet_title = post.retweet_title
      retweet_content = post.retweet_text
      quote_content = "<h3>#{retweet_title}</h3><p>#{retweet_content}</p>"
    end
    
    html_content = "<html>
<head>
	<meta http-equiv=\"Content-type\" content=\"text/html; charset=utf-8\">
	<title>#{title}</title>
	<style type=\"text/css\" media=\"all\">
		body {
			font-family: \"SimSun\", \"Palatino Linotype\", \"Book Antiqua\", Palatino, serif;
			font-size: 18px;
		}
		img {
			max-width: 768px; 
		}
		H1 {
		    font-family: STFangsong, Fangsong, serif, \"Palatino Linotype\", \"Book Antiqua\", Palatino, serif;
		}

		H2 {
		    font-family: STFangsong, Fangsong, serif, \"Palatino Linotype\", \"Book Antiqua\", Palatino, serif;
		    margin-bottom: 60px;
		    margin-bottom: 40px;
		    padding: 5px;
		    border-bottom: 1px LightGrey solid;
		    width: 90%;
		    line-height: 150%;
		}

		H3 {
		    font-family: STFangsong, Fangsong, serif, \"Palatino Linotype\", \"Book Antiqua\", Palatino, serif;
		    margin-top: 40px;
		    margin-bottom: 30px;
		    border-bottom: 1px LightGrey solid;
		    width: 80%;
		    line-height: 150%;
		}

		H4 {
		    font-family: STFangsong, Fangsong, serif, \"Palatino Linotype\", \"Book Antiqua\", Palatino, serif;
		}
    
		H5 {
		    font-family: STFangsong, Fangsong, serif, \"Palatino Linotype\", \"Book Antiqua\", Palatino, serif;
		}

		li {
		    margin-left: 10px;
		}
		blockquote {
			border-left: 4px lightgrey solid;
			padding-left: 5px;
			margin-left: 20px;
		}
		a {
			color: #000;
		}
	</style>
</head>
<body>
	<h2>#{title}</h2>
	<p>#{content}</p>
	<blockquote>#{quote_content}</blockquote>
  <span>#{created_at}</span>
	<h4><p><a href=\"http://xueqiu.com/#{author_id}/#{tid}\">原文链接</a></p></h4>
  </body>
</html>"
    return html_content
  end
  
  def fetch
    posts = @xueqiu.fetch_timeline @aid
    posts.each do |post|
      html_content = make_post_content post
      puts "#{html_content}"
    end
  end

  
end
