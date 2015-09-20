#!/usr/bin/env ruby
require_relative 'crawler'
require_relative 'pdfmaker'
require_relative 'mailer'

args = Hash[ ARGV.flat_map{|s| s.scan(/--?([^=\s]+)(?:=(\S+))?/) } ]

def print_help
  puts "  -h This help info
  
  Post
    -f fetch user's post
    usage:
    -f={user id}
    -f={user id}/{post id}
    
    Save mode:
      -c with comments
      -pdf convert to pdf
    Email mode:
      -c with comments
      -e send email
      
  Cube
    -z fetch cube
    usage:
    -z={cube_symbol}
  "
end

if args.has_key?('h')
  print_help
elsif args.has_key?('f')
  crawler = Crawler.new
  crawler.with_comments = true if args.has_key?('c')
  
  if args.has_key?('e')
    # email mode
    crawler.author_id = (args['f'])
    
    mailer = Mailer.new(crawler)
    mailer.continues_comments = true if args.has_key?('c')
    mailer.send_latest_post_if_needed
  else
    # normal
    if (args['f'].include? "/")
      # author_id/post_id
      params = args['f'].split("\/")
      crawler.fetch(params[0], params[1])
    
      if args.has_key?('pdf')
        puts "Start convert PDF for #{crawler.author_name} (#{crawler.author_id})"

        maker = PDFMaker.new
        maker.author_id = crawler.author_id
        maker.author_name = crawler.author_name
        maker.convert_single(params[1])
      end
    else
      # All posts of author_id
      crawler.fetch(args['f'])

      if args.has_key?('pdf')
        puts "Start convert PDF for #{crawler.author_name} (#{crawler.author_id})"
      
        maker = PDFMaker.new
        maker.author_id = crawler.author_id
        maker.author_name = crawler.author_name
        maker.convert
      end
    end
  end
  
elsif args.has_key?('z')
  if (args['z'].include? ",")
    cubes_id = args['z'].split(",")
  else
    cubes_id = [args['z']]
  end
  
  crawler = Crawler.new
  cubes_id.each {|cube_id| crawler.fetch_cube(cube_id)}
else
  print_help
end
