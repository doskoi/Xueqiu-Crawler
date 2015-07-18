#!/usr/bin/env ruby
require 'bundler/setup'
require 'rest-client'
require 'json'
require 'date'
require_relative 'model/post'
require_relative 'model/comment'
require_relative 'model/transaction'
require_relative 'model/user_transaction'

class XueqiuEngine
  attr_accessor :token
  
  def initialize
    @with_comments = false
  end

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
        puts "Got token: #{@token}"
      end
    rescue => e
      puts "Get token failed: #{e.inspect}"
    end
  end
  
  def fetch_cube(cube_id)
    transactions = Array.new
    maxPage = 1
    get_actions = Proc.new do |json|
      json['list'].each do |list|
        t = Transaction.new
        t.id = list['id']
        t.created_at = Time.at(list['created_at'].to_s[0..9].to_i).to_datetime
        t.status = list['status']
        t.cash = list['cash']
        t.net_value = list['cash_value']
        t.category = list['category']
        
        if list['rebalancing_histories'].count > 0
          trades = Array.new
          list['rebalancing_histories'].each do |trade|
            ut = UserTransaction.new
            ut.id = trade['id']
            ut.created_at = Time.at(trade['created_at'].to_s[0..9].to_i).to_datetime
            ut.stock_name = trade['stock_name']
            ut.stock_symbol = trade['stock_symbol']
            ut.price = trade['price']
            ut.prev_price = trade['prev_price']
            ut.net_value = trade['net_value']
            ut.prev_net_value = trade['prev_net_value']
            ut.weight = trade['weight']
            ut.target_weight = trade['target_weight']
            ut.prev_target_weight = trade['prev_target_weight']
            ut.prev_weight_adjusted = trade['prev_weight_adjusted']
            
            trades.push ut
          end
          t.trades = trades
        end
        
        transactions.push t
      end
    end
    
    begin
      response = RestClient.get 'https://api.xueqiu.com/cubes/rebalancing/history.json',
                  {:params => {
                  'access_token' => self.token,
                  'cube_symbol' => cube_id,
                  'count' => 50,
                  'page' => 1}}
                  
      puts "Get sample #{response.code}"
      case response.code
      when 200
        json = JSON.parse response
        maxPage = json['maxPage']
        get_actions.call json
      end
    rescue => e
      puts "Get sample failed: #{e.inspect}"
    end
    
    (2..maxPage).each do |page|
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
          get_actions.call json
        end
      rescue => e
        puts "Get cube failed: #{e.inspect}"
      end
    end
    
    transactions
  end
  
  def fetch_comments_excellent(post_id)
    puts "Get excellent comments for #{post_id}"
        
    response = RestClient.get 'https://api.xueqiu.com/statuses/comments_excellent.json',
                {:params => {
                'access_token' => self.token,
                'id' => post_id,
                'count' => 5}}
    json = JSON.parse response
    json['comments'].each do |comment_json|
      comment = Comment.new
      comment.id = comment_json['id']
      comment.text = comment_json['text']
      comment.author_id = comment_json['user_id']
      comment.author_screenname = comment_json['user']['screen_name']
      comment.created_at = Time.at(comment_json['created_at'].to_s[0..9].to_i).to_datetime
      comment.reply_comment_id = comment_json['in_reply_to_comment_id']
      comments.push comment
    end
    
    return comments
  end
  
  def fetch_comments(post_id)
    puts "Get comments for #{post_id}"
        
    comments = Array.new
    maxPage = 1
    
    get_comment = Proc.new do |json|
      json['comments'].each do |comment_json|
        comment = Comment.new
        comment.id = comment_json['id']
        comment.text = comment_json['text']
        comment.author_id = comment_json['user_id']
        comment.author_screenname = comment_json['user']['screen_name']
        comment.created_at = Time.at(comment_json['created_at'].to_s[0..9].to_i).to_datetime
        comment.reply_comment_id = comment_json['in_reply_to_comment_id']
        comments.push comment
      end
    end
    
    response = RestClient.get 'https://api.xueqiu.com/statuses/comments.json',
                {:params => {
                'access_token' => self.token,
                'id' => post_id,
                'asc' => 0,
                'count' => 200,
                'page' => 1}}
    json = JSON.parse response
    puts "Comments Page 1 of Post #{post_id}"
    maxPage = json['maxPage']
    get_comment.call json
    
    if maxPage > 1
      (2..maxPage).each do |page|
        response = RestClient.get 'https://api.xueqiu.com/statuses/comments.json',
                    {:params => {
                    'access_token' => self.token,
                    'id' => post_id,
                    'asc' => 0,
                    'count' => 200,
                    'page' => page}}
        json = JSON.parse response
        puts "Comments Page #{page} of Pages #{maxPage}"
        get_comment.call json
        sleep 0.1
      end
    end
    
    return comments
  end
  
  def fetch_timeline(author_id)
    posts = Array.new
    maxPage = 1

    begin
      response = RestClient.get 'https://xueqiu.com/v4/statuses/user_timeline.json',
                  {:params => {'access_token' => self.token,
                      'count' => 20,
                      'user_id' => author_id,
                      'page' => 1}}
                    
      puts "Get timeline list #{response.code}"
      case response.code
      when 200
        json = JSON.parse response
        puts "Page 1 of User: #{author_id}"
        maxPage = json['maxPage']
        json['statuses'].each do |post|
          posts.push post['id']
        end
        
        if maxPage > 1
          (2..maxPage).each do |page|
            response = RestClient.get 'https://xueqiu.com/v4/statuses/user_timeline.json',
                        {:params => {'access_token' => self.token,
                            'count' => 50,
                            'user_id' => author_id,
                            'page' => page}}
                            
            json = JSON.parse response
            puts "Page #{page} of Pages #{maxPage}"
            json['statuses'].each do |post|
              posts.push post['id']
            end
          end
        end
        return posts
      end
    rescue => e
      puts "Get timeline list failed: #{e.inspect}"
    end
  end
  
  def fetch_post(post_id, with_comments)
    begin
      response = RestClient.get 'https://api.xueqiu.com/statuses/show.json',
                  {:params => {
                      'access_token' => self.token,
                      'id' => post_id}}

      puts "Get post #{post_id} : code #{response.code}"
      case response.code
      when 200
        json = JSON.parse response
        post = Post.new
        post.id = json['id']
        post.title = json['title']
        post.text = json['text'].gsub(/!custom.jpg/) {""}
        post.author_id = json['user_id']
        post.author_screenname = json['user']['screen_name']
        post.created_at = Time.at(json['created_at'].to_s[0..9].to_i).to_datetime
        if json['retweeted_status']
          post.retweet_author_id = json['retweeted_status']['user_id']
          post.retweet_author_screenname = json['retweeted_status']['user']['screen_name']
          post.retweet_title = json['retweeted_status']['title']
          post.retweet_text = json['retweeted_status']['text'].gsub(/!custom.jpg/) {""}
        end
        if with_comments
          post.comments = self.fetch_comments post.id
        end
        return post
      end
    rescue => e
      puts "Get post failed: #{e.inspect}"
    end
  end
  
end

