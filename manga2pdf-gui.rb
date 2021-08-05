require 'selenium-webdriver'
require 'uri'
require 'ruby-progressbar'
require 'rmagick'
require 'libui'

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

UI = LibUI

init = UI.init

url, mkdir, chlimit, chlimit_toggle, savefile = nil, nil, 1, nil, nil
inner_thread = nil
running = false

should_quit = proc do
  puts 'Bye Bye'
  inner_thread.exit
  UI.control_destroy(MAIN_WINDOW)
  UI.quit
  0
end

# Main Window
MAIN_WINDOW = UI.new_window('Manga2PDF - GUI', 600, 200, 1)
UI.window_set_margined(MAIN_WINDOW, 1)
UI.window_on_closing(MAIN_WINDOW, should_quit)

hbox = UI.new_horizontal_box
UI.window_set_child(MAIN_WINDOW,hbox)
hbox = UI.new_horizontal_box
UI.box_set_padded(hbox, 1)

vbox = UI.new_vertical_box
UI.window_set_child(MAIN_WINDOW, vbox)
hbox = UI.new_horizontal_box
UI.box_set_padded(vbox, 1)
UI.box_set_padded(hbox, 1)

UI.box_append(vbox, hbox, 1)

group = UI.new_group('Manga2PDF')
UI.group_set_margined(group, 1)
UI.box_append(hbox, group, 1) # OSX bug?

entry = UI.new_entry
UI.entry_on_changed(entry) do
  url = UI.entry_text(entry).to_s
end

entry2 = UI.new_entry
UI.entry_on_changed(entry2) do
  savefile = UI.entry_text(entry2).to_s
end
inner = UI.new_vertical_box
UI.box_set_padded(inner, 1)
UI.group_set_child(group, inner)
group = UI.new_group('Enter the URL:')
UI.group_set_margined(group, 1)
UI.box_append(inner, group, 1)
UI.box_append(inner,entry,0)
group = UI.new_group('Savefile name:')
UI.group_set_margined(group, 1)
UI.box_append(inner, group, 1)


UI.box_append(inner,entry2,0)

# Checkbox
checkbox = UI.new_checkbox('Have separate folders for each chapter?')
UI.checkbox_on_toggled(checkbox) do |ptr|
  mkdir = UI.checkbox_checked(ptr) == 1
end
UI.box_append(inner, checkbox, 0)

checkbox2 = UI.new_checkbox('Download only a number of chapters')
UI.checkbox_on_toggled(checkbox2) do |ptr|
  chlimit_toggle = UI.checkbox_checked(ptr) == 1
end

group = UI.new_group('Max number of chapters')
UI.group_set_margined(group, 1)
UI.box_append(inner, group, 0)

# Spinbox
spinbox = UI.new_spinbox(1,9999)
UI.spinbox_set_value(spinbox, 1)
UI.spinbox_on_changed(spinbox) do |ptr|
  chlimit = UI.spinbox_value(ptr)
end
UI.box_append(inner, checkbox2, 0)
UI.box_append(inner, spinbox, 0)

# Progressbar
progressbar = UI.new_progress_bar

inner2 = UI.new_vertical_box
UI.box_set_padded(inner2, 1)
# Button
button = UI.new_button('Download')
label = UI.new_label("Waiting")
UI.button_on_clicked(button) do
  if not running
    running = true
      inner_thread = Thread.new{
        UI.label_set_text(label,"Initializing WebScraper")
        UI.progress_bar_set_value(progressbar, 5)
        chlimit = nil if not chlimit_toggle
        manga = Manga2PDF::MangaIMG.new(url,mkdir,chlimit,savefile)
        UI.label_set_text(label,"Moving to #{url}")
        UI.progress_bar_set_value(progressbar, 15)
        UI.label_set_text(label,"Downloading images")
        manga.get_img_all
        UI.label_set_text(label,"Finished downloading images")
        UI.progress_bar_set_value(progressbar, 75)
        UI.label_set_text(label,"Merging images")
        manga.merge_to_pdf
        UI.progress_bar_set_value(progressbar, 100)
        UI.label_set_text(label,"Finished! You can close the window now")
      }
  end

end
UI.box_append(inner, button, 0)
UI.box_append(inner, progressbar, 0)
UI.box_append(inner,label,0)


UI.control_show(MAIN_WINDOW)

UI.main
inner_thread.join

UI.quit


