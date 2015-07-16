#!/usr/bin/env ruby
require_relative 'crawler'
require_relative 'pdfmaker'

args = Hash[ ARGV.flat_map{|s| s.scan(/--?([^=\s]+)(?:=(\S+))?/) } ]

if args.has_key?('f')
  crawler = Crawler.new
  crawler.with_comments = true if args.has_key?('c')
  
  if (args['f'].include? "/")
    params = args['f'].split("\/")
    crawler.fetch(params[0], params[1])
    
    if args.has_key?('pdf')
      puts "Start convert PDF"

      maker = PDFMaker.new
      maker.author_id = crawler.author_id
      maker.author_name = crawler.author_name
      maker.convert_single(params[1])
    end

  else
    crawler.fetch(args['f'])

    if args.has_key?('pdf')
      puts "Start convert PDF"
      
      maker = PDFMaker.new
      maker.author_id = crawler.author_id
      maker.author_name = crawler.author_name
      maker.convert
    end
  end
else
  puts "Exit"
end

# ./worker -f=user_id
# ./worker -f=user_id/post_id -c
# ./worker -f=user_id/post_id -p