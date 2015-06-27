#!/usr/bin/env ruby
require 'bundler/setup'
require 'fileutils'
require 'pdfkit'

class Maker
  attr_accessor :aid
  
  def initialize
  end
    
  def post_path
    path = File.expand_path("posts/#{@aid}", File.dirname(__FILE__))
    FileUtils.mkdir_p path
    return path
  end

  def filename2path (filename)
    File.expand_path("#{filename}.html", post_path)
  end
  
  def convert
    if File.directory?(post_path)
      files = Array.new
      
      Dir.foreach(post_path) do |file|
        if File.extname(file) == '.html'
          file_path = File.join(post_path, file)
          html_content = File.read(file_path)
          html_content.scrub!
          
          kit = PDFKit.new(html_content)
          save_name = File.basename file, '.html'
          kit.to_file(File.expand_path("#{save_name}.pdf", post_path))
        end
      end
    end
  end
end

if ARGV.count == 1
  m = Maker.new
  m.aid = ARGV.first
  m.convert
else
  puts "Wrong argument"
end