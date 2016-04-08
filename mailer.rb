#!/usr/bin/env ruby
require 'bundler/setup'
require 'open-uri'
require 'fileutils'
require_relative 'crawler'
require 'mail'

class Mailer
  attr_accessor :author_id, :use_on_hold, :continues_comments
  
  PRODUCTION_ENV = File.expand_path("production", File.dirname(__FILE__))
  QR_CODE_PATH = File.expand_path("qr-code.gif", File.dirname(__FILE__)) 
  
  def initialize (arg)
    @crawler = arg
    @crawler.mail_mode = true
    @author_id = @crawler.author_id
    @use_on_hold = false
    @continues_comments = false
  end
  
  def deliverd_path
    path = File.expand_path("posts/#{@author_id}/deliverd", File.dirname(__FILE__))
    FileUtils.mkdir_p path
    return path
  end
  
  def checkpoint_path
    File.expand_path("latest_post", deliverd_path)
  end
  
  def delivered_post_path (post_id)
    File.expand_path("#{post_id}", deliverd_path)
  end
  
  def delivered_comment_path (post_id, comment_id)
    File.expand_path("#{post_id}_#{comment_id}", deliverd_path)
  end
  
  def production?
    if File.exist? PRODUCTION_ENV
      true
    else
      false
    end
  end
  
  def production_receiver
    File.read PRODUCTION_ENV
  end
  
  def new_post_available?
    if File.exist?(checkpoint_path)
      local_latest_id = File.read(checkpoint_path)
    end
    
    @latest_id = @crawler.fetch_lastest_post_id(@author_id)
    
    if local_latest_id.to_s == @latest_id.to_s
      return false
    else
      return true
    end
  end
  
  def send_latest_post_if_needed
    if new_post_available?
      puts "fetch new post"
      # Same post won't deliver again
      return if File.exist?(delivered_post_path(@latest_id))
      # fetch the new post
      @crawler.fetch(@author_id, @latest_id)
      # read saved content
      content = File.read(@crawler.post_path(@latest_id))
      # send content
      send_content("#{@crawler.author_name} (#{@latest_id})", content)
      
      # save latest id
      File.open(checkpoint_path, 'w') do |f|
          f.write(@latest_id)
      end
      # save post flag
      File.open(delivered_post_path(@latest_id), 'w') do |f|
          f.write("")
      end
    else
      puts "no found new post"
      # don't have new post but try to fetch commnets if needs
      if @continues_comments
        puts "then fetch comments"
        # get last post id
        post_id = File.read(checkpoint_path)
        post_id = @crawler.fetch_lastest_post_id(@crawler.author_id) if post_id == nil
        # fetch new comments
        comments_id_array = @crawler.fetch_comments(post_id)
        
        content = ""
        comments_id_array.each do |comment_id|
          # Same comment won't deliver again
          next if File.exist?(delivered_comment_path(post_id, comment_id))
          
          # read comments
          content << File.read(@crawler.comment_path(post_id, comment_id))          
          # save sent comment_id
          File.open(delivered_comment_path(post_id, comment_id), 'w') do |f|
              f.write("")
          end
        end
        if content.length > 0
          content << " <h4><p><a href=\"http://xueqiu.com/#{@author_id}/#{post_id}\">原文链接</a></p></h4>"
          # send comment
          send_content("#{@crawler.author_name} 回复在(#{post_id})", content)
        end
      end      
    end
  end
  
  def send_content(topic, content)
    if @crawler.mail_on_hold == true && @use_on_hold == true
        return
    end
    
    email_receiver = (production?) ? production_receiver : "sandbox@mg.sh3ng.com"
    
    mail_type = (@crawler.mail_real_time) ? "realtime" : "normal"
    puts "Sending #{mail_type} post #{topic} to #{email_receiver}"
    
    # via API
    inline_file = (@real_time) ? File.new(QR_CODE_PATH) : ""
    
    data = Hash.new { |hash, key| hash[key] = [] }  
    data[:from] = "雪球更新推送 <noreply@mg.sh3ng.com>",
    data[:to] = email_receiver,
    data[:subject] = topic
    data[:html] = content
    data[:inline] = inline_file
    RestClient.post "https://api:key-a97de83c83cf3a3cc7de21902224f4d8"\
    "@api.mailgun.net/v3/mg.sh3ng.com/messages", data
  end
end