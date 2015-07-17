#!/usr/bin/env ruby
require 'bundler/setup'
require 'fileutils'
require 'pdfkit'
require 'combine_pdf'

class PDFMaker
  attr_accessor :author_id, :author_name
  
  def initialize
  end
    
  def post_path
    path = File.expand_path("posts/#{@author_id}", File.dirname(__FILE__))
    FileUtils.mkdir_p path
    return path
  end
  
  def save_path
    path = File.expand_path("posts/#{@author_id}/PDF", File.dirname(__FILE__))
    FileUtils.mkdir_p path
    return path
  end
  
  def make_cover
    content = "<html>
    <head>
    <meta http-equiv=\"Content-type\" content=\"text/html; charset=utf-8\">
    <title></title>
    <style type=\"text/css\" media=\"all\">
    #createAt
    {
        position: absolute;
        left: 498px;
        width: 231px;
        top: 32px;
        height: 31px;
        background: none;
        border: none;
        font-size: 16px;
        text-align: right;
        font-family: AdobeFangsongStd-Regular;
        color: rgb(0, 0, 0);
    }
    #author_name
    {
        position: absolute;
        left: 34px;
        width: 700px;
        top: 340px;
        height: 131px;
        background: none;
        border: none;
        font-size: 128px;
        text-align: center;
        font-family: AdobeFangsongStd-Regular;
        color: rgb(0, 0, 0);
    }
    #footer
    {
        position: absolute;
        left: 33px;
        width: 701px;
        top: 988px;
        height: 28px;
        background: none;
        border: none;
        font-size: 16px;
        text-align: left;
        font-family: AdobeFangsongStd-Regular;
        color: rgb(0, 0, 0);
    }
    #publisher
    {
    	color: #000;
    }
    </style>
    <meta charset=\"UTF-8\">
    </head>

    <body>
        <div id=\"createAt\">
        截止于#{Time.now.strftime("%Y年%m月%d日")}
        </div>
        <div id=\"author_name\">
        #{@author_name}
        </div>
        <div id=\"footer\">
        <a href=\"http://xueqiu.com/6023636062\" class  id=\"publisher\">DireWolf</a>出版，仅供学习交流，文章版权归原作者所有，非原作者授权禁止用于任何商业用途。
        </div>
    </body>

    </html>
    "
    pdf_path = File.expand_path("00000001.pdf", save_path)
    kit = PDFKit.new(content, :page_size => 'A4')
    kit.to_file(pdf_path)
    pdf_path
  end
  
  def convert_html(arg)
    html_path = File.expand_path("#{arg}.html", post_path)
    
    pdf_path = File.expand_path("#{arg}.pdf", save_path)
    
    if File.exist?(pdf_path)
      puts "PDF #{pdf_path} are exist"
    else
      html_content = File.read(html_path)
      html_content.scrub!
    
      kit = PDFKit.new(html_content, :page_size => 'A4')
      kit.to_file(pdf_path)
      puts "Saving PDF #{pdf_path}"
    end
    pdf_path
  end

  
  def convert_htmls
    Dir.foreach(post_path) do |file|
      if File.extname(file) == '.html'
        save_name = File.basename file, '.html'
        pdf_path = File.expand_path("#{save_name}.pdf", save_path)
        
        if File.exist?(pdf_path)
          puts "PDF #{save_name} are exist"
        else
          file_path = File.join(post_path, file)
          html_content = File.read(file_path)
          html_content.scrub!
        
          kit = PDFKit.new(html_content, :page_size => 'A4')
          kit.to_file(pdf_path)
          puts "Saving PDF #{save_name}"
        end
      end
    end
  end
  
  def combine_single(pdfs)
    puts "Combining PDFs #{@author_name}"
    pdf = CombinePDF.new
    
    pdfs.each do |file|
      pdf << CombinePDF.load(file)
    end
    
    pdf.save(File.expand_path("posts/#{@author_name}_#{@single}.pdf", File.dirname(__FILE__)))
  end

  
  def combine
    puts "Combining PDFs #{@author_name}"
    pdf = CombinePDF.new
    
    Dir.foreach(save_path) do |file|
      if File.extname(file) == '.pdf'
        file_path = File.join(save_path, file)
        pdf << CombinePDF.load(file_path)
      end
    end
    # pdf.number_pages
    pdf.save(File.expand_path("posts/#{@author_name}.pdf", File.dirname(__FILE__)))
  end

  def convert
    if File.directory?(post_path)
      make_cover
      convert_htmls
      combine
    end
  end
  
  def convert_single(arg)
    @single = arg
    if File.directory?(post_path)
      pdf_cover = make_cover
      pdf_content = convert_html(arg)
      combine_single([pdf_cover, pdf_content])
    end
  end

end
