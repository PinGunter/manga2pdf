require 'selenium-webdriver'
require 'uri'

module Manga2PDF
    class MangaIMG
        def initialize(url, mkdir)
            @url = url
            @end_state = false
            @global_count = 1
            @opts = Selenium::WebDriver::Firefox::Options.new(args: ['-headless'])            
            @driver = Selenium::WebDriver.for(:firefox, options: @opts)
            @driver.get @url
            @mkdir = mkdir
        end
        
        # method to "download" all images
        # it actually screenshots the html element 
        # to bypass server restrictions
        def get_img
            images = @driver.find_elements(tag_name: 'img')
            while @driver.title == "(1) New Message!"
            end
            dir_path = "."
            dir_path = "#{@driver.title}" if @mkdir
            if not Dir.exists? dir_path
                Dir.mkdir dir_path
            end
            index = 0
            images.each do |img|
                if index > 0 and index < images.length - 1
                    scrn_dir = "#{@global_count}_#{index}.png"
                    scrn_dir = "#{dir_path}/#{index}.png" if @mkdir
                    img.save_screenshot scrn_dir
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
        end

        # method to download all images from all volumes
        def get_img_all
            while not @end_state
                while @driver.title == "(1) New Message!"
                end
                puts "Currently downloading: #{@driver.title}"
                get_img
                next_page
                @global_count += 1
            end
            puts "Finished!"
        end

    end
end

if __FILE__ == $0
    url = nil
    mkdir = nil
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
    end

    if url.nil? and mkdir.nil? 
        raise "URL was not provided."
    end

    manga = Manga2PDF::MangaIMG.new(url,mkdir)
    manga.get_img_all
end