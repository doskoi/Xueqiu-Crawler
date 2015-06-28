#!/usr/bin/env ruby
require_relative 'crawler'
require_relative 'pdfmaker'

if ARGV.count == 1
  crawler = Crawler.new
  crawler.aid = ARGV.first

  while crawler.fetch > 0
    puts "---------------"
  end
  
  puts "Start convert PDF"
  
  maker = PDFMaker.new
  maker.aid = crawler.aid
  maker.author = crawler.author
  maker.convert
else
  puts "Wrong argument"
end