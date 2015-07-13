#!/usr/bin/env ruby
require_relative 'crawler'
require_relative 'pdfmaker'

if ARGV.count <= 2
  if (ARGV.first.include? "/")
    args = ARGV.first.split("\/")
    crawler = Crawler.new

    crawler.fetch(args[0], args[1])
    
    if ARGV[1] == "pdf"
      puts "Start convert PDF"

      maker = PDFMaker.new
      maker.author_id = crawler.author_id
      maker.author_name = crawler.author_name
      maker.convert_single(args[1])
    end

  else
    crawler = Crawler.new

    crawler.fetch(ARGV.first)
  
    if ARGV[1] == "pdf"
      puts "Start convert PDF"

      maker = PDFMaker.new
      maker.author_id = crawler.author_id
      maker.author_name = crawler.author_name
      maker.convert
    end
  end
else
  puts "Wrong argument"
end

# ./worker user_id
# ./worker user_id/post_id
# ./worker user_id/post_id pdf