#!/usr/bin/env ruby
require 'bundler/setup'
require 'rest-client'
require 'json'
require 'fileutils'
require_relative 'xueqiu'

class Crawler
  attr_accessor :author_id, :author_name, :with_comments

  def initialize
    @xueqiu = XueqiuEngine.new
    @access_token = @xueqiu.token
    @with_comments = false
  end
  
  def post_path
    path = File.expand_path("posts/#{@author_id}", File.dirname(__FILE__))
    FileUtils.mkdir_p path
    return path
  end
  
  def filename2path (filename)
    File.expand_path("#{filename}.html", post_path)
  end
    
  def make_post_content(post)
    @author_name = post.author_screenname if !@author_name
    
    tid = post.id
    author_id = post.author_id
    title = post.title
    content = post.text
    created_at = post.created_at_readable
    quote_content = ""
    if post.retweet_text
      quote_content = "<a href=\"http://xueqiu.com/#{post.retweet_author_id}\">#{post.retweet_author_screenname}</a>: <h3>#{post.retweet_title}</h3><p>#{post.retweet_text}</p>"
    end
    comments_content = ""
    if post.comments
      post.comments.each do |comment|
        if comment.author_id == post.author_id
          comments_content << "<a href=\"http://xueqiu.com/#{comment.author_id}\">#{comment.author_screenname}</a>:
          <div class=\"commnet\">#{comment.text}</div>
          <span>#{comment.created_at_readable}</span>"
          if comment.reply_comment_id
            reply_comment = (post.comments.select {|c| c.id == comment.reply_comment_id}).first
            if reply_comment
              comments_content << "<blockquote><a href=\"http://xueqiu.com/#{reply_comment.author_id}\">#{reply_comment.author_screenname}</a>:
          <div class=\"commnet\">#{reply_comment.text}</div>
          <span>#{reply_comment.created_at_readable}</span></blockquote>"
            end
          end
          comments_content << "<hr>"
        end
      end
    end
    if comments_content.length > 0
      comments_content = "<h3>评论</h3>" + comments_content
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
		    width: 90%;
		    line-height: 150%;
		}

		H3 {
		    font-family: STFangsong, Fangsong, serif, \"Palatino Linotype\", \"Book Antiqua\", Palatino, serif;
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
  <div>#{comments_content}</div>
	<h4><p><a href=\"http://xueqiu.com/#{author_id}/#{tid}\">原文链接</a></p></h4>
  </body>
</html>"
    return html_content
  end
  
  def fetch (author_id, *args)
    @author_id = author_id
    
    save_post = Proc.new do |post|
      html_content = make_post_content post
      if html_content
        puts "Save post #{post.id}"
        File.open(filename2path(post.id), 'w') do |f|
            f.write(html_content)
        end
      else
        puts "Post #{post.id} cannot parese json"
      end
    end
    
    if args.count > 0
      args.each do |post_id|
        save_post.call @xueqiu.fetch_post(post_id, @with_comments)
      end
    else
      posts_id_array = @xueqiu.fetch_timeline @author_id
      
      posts_id_array.each do |post_id|
        if File.exist?(filename2path(post_id))
          puts "Post #{post_id} are exist"
        else
          # not exist
          save_post.call @xueqiu.fetch_post(post_id, @with_comments)
        end
      end
    end
    
  end

  
end
