#!/usr/bin/env ruby
require 'bundler/setup'
require 'rest-client'
require 'json'
require 'fileutils'
require_relative 'xueqiu'

class Crawler
  attr_accessor :author_id, :author_name, :with_comments, :mail_mode, :mail_on_hold, :mail_real_time

  def initialize
    @xueqiu = XueqiuEngine.new
    @access_token = @xueqiu.token
    @with_comments = false
    @mail_mode = false
    @mail_on_hold = false
    @mail_real_time = false
  end
  
  # /post/#{author_id}/#{post_id}.html
  def post_path (post_id)
    path = File.expand_path("posts/#{@author_id}", File.dirname(__FILE__))
    FileUtils.mkdir_p path if Dir.exist?(path) == false
    return File.expand_path("#{post_id}.html", path)
  end
  
  # /post/#{author_id}/#{post_id}/#{post_id}_#{comment_id}.html
  def comment_path (post_id, comment_id)
    path = File.expand_path("posts/#{@author_id}/#{post_id}", File.dirname(__FILE__))
    FileUtils.mkdir_p path if Dir.exist?(path) == false
    return File.expand_path("#{post_id}_#{comment_id}.html", path)
  end
  
  # /cube/#{cube_id}.html
  def cube_path(cube_id)
    path = File.expand_path("cube", File.dirname(__FILE__))
    FileUtils.mkdir_p path if Dir.exist?(path) == false
    return File.expand_path("#{cube_id}.html", path)
  end
  
  def make_comment_content(comment, all_comments)
    comments_quote = ""
    
    if comment.author_id.to_s == @author_id.to_s
      @author_name = comment.author_screenname if !@author_name
      
      comments_quote << "<a href=\"http://xueqiu.com/#{comment.author_id}\">#{comment.author_screenname}</a>:
      <div class=\"commnet\">#{comment.text}</div>
      <span>#{comment.created_at_readable}</span>"
      if comment.reply_comment_id
        reply_comment = (all_comments.select {|c| c.id == comment.reply_comment_id}).first
        if reply_comment
          comments_quote << "<blockquote><a href=\"http://xueqiu.com/#{reply_comment.author_id}\">#{reply_comment.author_screenname}</a>:
      <div class=\"commnet\">#{reply_comment.text}</div>
      <span>#{reply_comment.created_at_readable}</span></blockquote>"
        end
      end
    end
    
    return nil if comments_quote.length == 0
    
    comment_content = "<html>
      <head>
      	<meta http-equiv=\"Content-type\" content=\"text/html; charset=utf-8\">
        	<title></title>
        	<style type=\"text/css\" media=\"all\">
        		body {
        			font-family: \"SimSun\", \"Palatino Linotype\", \"Book Antiqua\", Palatino, serif;
        			font-size: 18px;
        		}
        		H3 {
        		    font-family: STFangsong, Fangsong, serif, \"Palatino Linotype\", \"Book Antiqua\", Palatino, serif;
        		    width: 80%;
        		    line-height: 150%;
        		}
        		H4 {
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
      <div>#{comments_quote}</div>
      </body>
    </html>"

    return comment_content
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
    
    if @mail_mode
      @mail_on_hold = true
      @mail_real_time = false
  
      code = content[/(00|30|60)\d{4}/]
      if (code && code.length == 6)
          @mail_on_hold = false
          @mail_real_time = true if content.length < 140
      end
  
      donate_content = (@real_time) ? "
        <div>
      		<h5><p>打赏二维码
      		</p></h5>
      		<img src=\"cid:qr-code.gif\">
      	</div>
        " : ""
        
        unsubscribe_content = "<h5><p><a href=\"%mailing_list_unsubscribe_url%\">从此邮件列表退订</a></p></h5>"

        email_content = ""
        email_content << donate_content
        email_content << unsubscribe_content
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
      <p>#{email_content}</p>
      </body>
    </html>"

    return html_content
  end
  
  def make_transactions_content(cube, transactions)
    content =""
    
    transactions.each do |transaction|
      next if (transaction.status != "success" || transaction.category == "sys_rebalancing")
      content << "<div>
      <div>#{transaction.created_at_readable}<span class=\"netvalue\">现金值: #{transaction.cash_value.round(2)}</span><span class=\"cash\">现金: #{transaction.cash}%</span></div>
      <!--<span class=\"#{transaction.status}\">#{transaction.status_readable}</span>-->
      <span>#{transaction.category_readable}</span>
      <ul>"
      if transaction.trades
        transaction.trades.each do |ut|
          content << "<li>#{ut.stock_name} (#{ut.stock_symbol}) ¥#{ut.price} <br/> #{ut.prev_weight_adjusted}% -> #{ut.target_weight}%</li>"
        end
      end
      content << "</ul>"
      content << "<span class=\"comment\">“#{transaction.comment}”</span>" if transaction.comment && transaction.comment != ""
      content << "</div><hr/>"
    end
    
    html_content = "<html>
    <head>
      <title>#{cube.name}</title>
    	<meta http-equiv=\"Content-type\" content=\"text/html; charset=utf-8\">
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
		
    		.failed {
    			color: #cc0000;
    		}
		
    		.canceled {
    			color: #999;
    		}
		
    		.success {
    			color: #00cc00;
    		}
        
        .comment {
          margin-left: 10px;
          font-family: STFangsong, Fangsong, serif, \"Palatino Linotype\", \"Book Antiqua\", Palatino, serif;
        }
        
    		.netvalue {
    			padding-left: 10px;
          font-family: STFangsong, Fangsong, serif, \"Palatino Linotype\", \"Book Antiqua\", Palatino, serif;
    		}
        
    		.cash {
    			padding-left: 10px;
          font-family: STFangsong, Fangsong, serif, \"Palatino Linotype\", \"Book Antiqua\", Palatino, serif;
    		}
    	</style>
    </head>
    <body>
      <h2><a href=\"http://xueqiu.com/P/#{cube.symbol}\">#{cube.name}</a></h2>
      <h3>净值: #{cube.net_value}</h3>
      <p>日回报率: #{cube.daily_gain} 月回报率: #{cube.monthly_gain} 年回报率: #{cube.annualized_gain} 总回报: #{cube.total_gain}</p>
    	<p>#{content}</p>
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
        File.open(post_path(post.id), 'w') do |f|
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
        if File.exist?(post_path(post_id))
          puts "Post #{post_id} are exist"
        else
          # not exist
          save_post.call @xueqiu.fetch_post(post_id, @with_comments)
        end
      end
    end
  end
  
  def fetch_comments(post_id)
    puts "fetch comments for #{post_id}"
    save_comment = Proc.new do |comment, all_comments|
      comment_content = make_comment_content(comment, all_comments)
      
      if comment_content
        puts "Save comment #{post_id}_#{comment.id}"
        File.open(comment_path(post_id, comment.id), 'w') do |f|
            f.write(comment_content)
        end
      else
        puts "Post #{post_id}_#{comment.id} cannot parese json"
      end
    end
    
    # Fetch all comments of post id
    comments_array = @xueqiu.fetch_comments post_id
    comments_id_array = Array.new
    
    comments_array.each do |comment|
        if comment.author_id.to_s == @author_id.to_s
          # check comment exist
          if File.exist?(comment_path(post_id, comment.id))
            puts "Comment #{post_id}_#{comment.id} are exist"
          else
            # not exist
            save_comment.call(comment, comments_array)
            comments_id_array.push comment.id.to_s
          end  
        end
    end
    
    return comments_id_array
  end
  
  def fetch_lastest_post_id(author_id)
    author_id = @author_id if author_id.nil?
    @xueqiu.fetch_lastest_post_id author_id
  end

  def fetch_cube (cube_id)
    cube = @xueqiu.fetch_cube_info(cube_id)
    transactions = @xueqiu.fetch_cube(cube_id)
    
    html_content = make_transactions_content(cube, transactions)
    if html_content
      puts "Save Cube transactions #{cube_id}"
      File.open(cube_path("#{cube.name}-#{cube.symbol}"), 'w') do |f|
          f.write(html_content)
      end
    else
      puts "Cube #{cube_id} cannot parese json"
    end
  end
  
end
