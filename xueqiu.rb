#!/usr/bin/env ruby
require 'bundler/setup'
require 'rest-client'
require 'json'
require 'date'
require_relative 'model/post'
require_relative 'model/comment'

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
  
  def fetch_cube(cube_id)
    actions = Array.new
    maxPage = 1
    get_actions = Proc.new do |json|
      json['list'].each {|list| actions.push list}
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
    
    puts "Get actions: #{actions.count}"
    actions
  end
  
  def fetch_comments_excellent(post_id)
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
      comment.created_at = DateTime.strptime(comment_json['created_at'].to_s, '%Q')
      comment.reply_comment_id = comment_json['in_reply_to_comment_id']
      comments.push comment
    end
    
    return comments
  end
  
  def fetch_comments(post_id)
    comments = Array.new
    maxPage = 1
    get_comment = Proc.new do |json|
      json['comments'].each do |comment_json|
        comment = Comment.new
        comment.id = comment_json['id']
        comment.text = comment_json['text']
        comment.author_id = comment_json['user_id']
        comment.author_screenname = comment_json['user']['screen_name']
        comment.created_at = DateTime.strptime(comment_json['created_at'].to_s, '%Q')
        comment.reply_comment_id = comment_json['in_reply_to_comment_id']
        comments.push comment
      end
    end
    
    response = RestClient.get 'https://api.xueqiu.com/statuses/comments.json',
                {:params => {
                'access_token' => self.token,
                'id' => post_id,
                'asc' => 0,
                'page' => 1}}
    json = JSON.parse response
    maxPage = json['maxPage']
    get_comment.call json
    
    if maxPage > 1
      (2..maxPage).each do |page|
        response = RestClient.get 'https://api.xueqiu.com/statuses/comments.json',
                    {:params => {
                    'access_token' => self.token,
                    'id' => post_id,
                    'asc' => 0,
                    'page' => page}}
        json = JSON.parse response
        get_comment.call json
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
        puts "#{json['statuses'].count} of Total: #{json['total']}"
        maxPage = json['maxPage']
        json['statuses'].each do |post|
          posts.push fetch_post(post['id'])
        end
        
        
        if maxPage > 1
          (2..maxPage).each do |page|
            response = RestClient.get 'https://xueqiu.com/v4/statuses/user_timeline.json',
                        {:params => {'access_token' => self.token,
                            'count' => 50,
                            'user_id' => author_id,
                            'page' => page}}

            json = JSON.parse response
            json['statuses'].each do |post|
              posts.push fetch_post(post['id'])
            end
          end
        end
        return posts
      end
    rescue => e
      puts "Get timeline list failed: #{e.inspect}"
    end
  end
  
  def fetch_post(post_id)
    begin
      response = RestClient.get 'https://api.xueqiu.com/statuses/show.json',
                  {:params => {
                      'access_token' => self.token,
                      'id' => post_id}}

      puts "Get post #{response.code}"
      case response.code
      when 200
        json = JSON.parse response
        post = Post.new
        post.id = json['id']
        post.title = json['title']
        post.text = json['text'].gsub(/!custom.jpg/) {""}
        post.author_id = json['user_id']
        post.author_screenname = json['user']['screen_name']
        post.created_at = DateTime.strptime(json['created_at'].to_s, '%Q')
        if json['retweeted_status']
          post.retweet_title = json['retweeted_status']['title']
          post.retweet_text = json['retweeted_status']['text'].gsub(/!custom.jpg/) {""}
        end
        post.comments = self.fetch_comments post.id
        return post
      end
    rescue => e
      puts "Get post failed: #{e.inspect}"
    end
  end
  
end

