#!/usr/bin/env ruby
require 'bundler/setup'
require 'fileutils'
require_relative 'crawler'
require 'mail'

class Mailer
  attr_accessor :author_id, :use_on_hold
  
  PRODUCTION_ENV = File.expand_path("production", File.dirname(__FILE__))
  QR_CODE_PATH = File.expand_path("qr-code.gif", File.dirname(__FILE__)) 
  
  def initialize (arg)
    @crawler = arg
    @crawler.mail_mode = true
    @author_id = @crawler.author_id
    @use_on_hold = false
  end
  
  def deliverd_path
    path = File.expand_path("posts/#{@author_id}/deliverd", File.dirname(__FILE__))
    FileUtils.mkdir_p path
    return path
  end
  
  def checkpoint_path
    File.expand_path("latest_post", deliverd_path)
  end
  
  def diliverd_post_path (arg)
    File.expand_path("#{arg}", deliverd_path)
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
    
    @latest_id = @crawler.fetch_lastest_post_id(@crawler.author_id)
    if local_latest_id == @latest_id
      return false
    else
      return true
    end
  end
  
  def send_latest_post_if_needed
    if new_post_available?

      return if File.exist?(diliverd_post_path(@latest_id))

      @crawler.fetch(@author_id, @latest_id)
      
      content = File.read(@crawler.post_path(@latest_id))
      
      send_content("#{@crawler.author_name} (#{@latest_id})", content)
      
      # save latest id
      File.open(checkpoint_path, 'w') do |f|
          f.write(@latest_id)
      end
      # save post flag
      File.open(diliverd_post_path(@latest_id), 'w') do |f|
          f.write("")
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