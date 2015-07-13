#!/usr/bin/env ruby
require_relative 'crawler'
require_relative 'pdfmaker'

if ARGV.count == 1
  # Whole
  if (ARGV.first.include? "/")
    args = ARGV.first.split("\/")
    crawler = Crawler.new
    crawler.aid = args[0]
    crawler.grab(args[1])
    
    puts "Start convert PDF"
    
    maker = PDFMaker.new
    maker.aid = crawler.aid
    maker.author = crawler.author
    maker.convert_single(args[1])
  else
    crawler = Crawler.new
    crawler.aid = ARGV.first

    crawler.fetch
  
    puts "Start convert PDF"

    maker = PDFMaker.new
    maker.aid = crawler.aid
    maker.author = crawler.author
    maker.convert
  end
else
  puts "Wrong argument"
end