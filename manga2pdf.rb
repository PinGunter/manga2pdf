require 'selenium-webdriver'
require 'uri'
require 'ruby-progressbar'
require 'rmagick'

module Manga2PDF
  class MangaIMG
    def initialize(url, mkdir, ch_limit, savefile)
      @url = url
      @end_state = false
      @global_count = 0
      @opts = Selenium::WebDriver::Firefox::Options.new(args: ['-headless'])
      @driver = Selenium::WebDriver.for(:firefox, options: @opts)
      @driver.get @url
      @mkdir = mkdir
      @current_title = @driver.find_element(tag_name: 'h1').text
      @ch_limit = ch_limit
      @img_list = []
      @savefile = check_savefile savefile
    end

    def check_savefile(savefile)
      if savefile[savefile.length-4, savefile.length] != ".pdf"
        return (savefile + ".pdf")
      end
      savefile
    end

    # method to "download" all images
    # it actually screenshots the html element
    # to bypass server restrictions
    def get_img
      images = @driver.find_elements(tag_name: 'img')
      progress_length = (images.length) -2
      progress_bar = ProgressBar.create(:title => "Progress", :total => progress_length, :length => 80)
      dir_path = "."
      dir_path = "#{@current_title}" if @mkdir
      if not Dir.exists? dir_path
        Dir.mkdir dir_path
      end
      index = 0
      images.each do |img|
        if index > 0 and index < images.length - 1
          scrn_dir = "#{@global_count}_#{index}.png"
          scrn_dir = "#{dir_path}/#{index}.png" if @mkdir
          img.save_screenshot scrn_dir
          @img_list << scrn_dir
          progress_bar.increment
        end
        index += 1
      end
    end

    # method to navigate to the next page

    def next_page
      begin
        next_btn = @driver.find_element(link_text: 'NEXT CHAPTER')
      rescue
        @end_state = true
      end
      if not @end_state
        next_btn.click
      end
      @current_title = @driver.find_element(tag_name: 'h1').text #update title
    end

    def merge_to_pdf
      puts "Starting merge"
      puts "output file: #{@savefile}"
      final_img_list = Magick::ImageList.new(*@img_list)
      final_img_list.write(@savefile)
      puts "Finished merging!"
    end

    # method to download all images from all volumes
    def get_img_all
      while not @end_state
        puts "Currently downloading: #{@current_title}"
        get_img
        next_page
        @global_count += 1
        if not @ch_limit.nil? and @global_count == @ch_limit
          @end_state = true
        end
      end
      puts "Finished downloading!"
    end



  end
end

if __FILE__ == $0
  url = nil
  mkdir = nil
  chlimit = nil
  savefile = "manga.pdf"
  if ARGV.length < 2
    raise "At least the url is needed for the script to run. Eg: ruby manga2pdf -u <url>."
  end

  for i in 0..ARGV.length
    if ARGV[i] == "-u"
      url = ARGV[i+1]
      i+=1
    end

    if ARGV[i] == "-d"
      mkdir = true
    end

    if ARGV[i] == "-l"
      chlimit = ARGV[i+1].to_i
      i+=1
    end

    if ARGV[i] == "-o"
      savefile = ARGV[i+1].to_s
      i+=1
    end
  end

  if url.nil?
    raise "URL was not provided."
  end

  manga = Manga2PDF::MangaIMG.new(url,mkdir,chlimit,savefile)
  manga.get_img_all
  manga.merge_to_pdf
end