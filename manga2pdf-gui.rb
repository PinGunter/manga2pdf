require 'selenium-webdriver'
require 'uri'
require 'ruby-progressbar'
require 'rmagick'
require 'glimmer-dsl-libui'

module Manga2PDF
  class MangaIMG
    def initialize(url, mkdir, ch_limit, savefile)
      @url = url
      @end_state = false
      @global_count = 0
      @opts = Selenium::WebDriver::Firefox::Options.new(args: ['-headless'])
      @driver = Selenium::WebDriver.for(:firefox, capabilities: @opts)
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
  
  class MangaGUI
    include Glimmer
    
    def initialize
      @url, @mkdir, @chlimit, @chlimit_toggle, @savefile = nil, nil, 1, nil, nil
      @inner_thread = nil
      @running = false
    end
    
    def launch
      window('Manga2PDF - GUI', 600, 200) {
        on_closing do
          @inner_thread.exit
        end
        
        margined true
        
        vertical_box {
          horizontal_box {
            group('Manga2PDF') {
              vertical_box {
                group('Enter the URL:')
                @entry = entry {
                  stretchy false
                  
                  on_changed do
                    @url = @entry.text
                  end
                }
                group('Savefile name:')
                @entry2 = entry {
                  stretchy false
                  
                  on_changed do
                    @savefile = @entry2.text
                  end
                }
                @checkbox = checkbox('Have separate folders for each chapter?') {
                  stretchy false
                  
                  on_toggled do
                    @mkdir = @checkbox.checked?
                  end
                }
                group('Max number of chapters')
                @checkbox2 = checkbox('Download only a number of chapters') {
                  stretchy false
                  
                  on_toggled do
                    @chlimit_toggle = @checkbox2.checked?
                  end
                }
                @spinbox = spinbox(1,9999) {
                  stretchy false
                  value 1
                  
                  on_changed do
                    @chlimit = @spinbox.value
                  end
                }
                @button = button('Download') {
                  stretchy false
                  
                  on_clicked do
                    if not @running
                      @running = true
                      @inner_thread = Thread.new do
                        Glimmer::LibUI.queue_main do
                          @label.text = "Initializing WebScraper"
                          @progressbar.value = 5
                        end
                        @chlimit = nil if not @chlimit_toggle
                        @manga = Manga2PDF::MangaIMG.new(@url,@mkdir,@chlimit,@savefile)
                        Glimmer::LibUI.queue_main do
                          @label.text = "Moving to #{@url}"
                          @progressbar.value = 15
                          @label.text = "Downloading images"
                        end
                        @manga.get_img_all
                        Glimmer::LibUI.queue_main do
                          @label.text = "Finished downloading images"
                          @progressbar.value = 75
                          @label.text = "Merging images"
                        end
                        @manga.merge_to_pdf
                        Glimmer::LibUI.queue_main do
                          @progressbar.value = 100
                          @label.text = "Finished! You can close the window now"
                        end
                        @running = false
                      end
                    end
                  end
                }
                @progressbar = progress_bar {
                  stretchy false
                }
                @label = label("Waiting") {
                  stretchy false
                }
              }
            }
          }
        }
      }.show
      @inner_thread.join
    end
  end
end

Manga2PDF::MangaGUI.new.launch
