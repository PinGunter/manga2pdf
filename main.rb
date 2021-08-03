require 'selenium-webdriver'
require 'faraday'

module Manga2PDF
    class MangaIMG

        def initialize(url)
            @url = url
            @end_state = false
            @global_count = 1
            @driver = Selenium::WebDriver.for :firefox
            @driver.get url
        end
        
        # method to "download" all images
        # it actually screenshots the html element 
        # to bypass server restrictions
        def get_img
            imagenes = @driver.find_elements(tag_name: 'img')
            index = 0
            imagenes.each do |img|
                img.save_screenshot("cap_#{@global_count}_#{index}.png")
                index += 1
            end
        end
        # avanzar a la siguiente pagina
        # siguiente_boton = driver.find_element(link_text: 'NEXT CHAPTER').click
        # if not siguiente_boton then
        #     finalizado = true
        # else
        #     siguiente_boton.click
        # end
    end
end

if __FILE__ == $0
    manga = Manga2PDF::MangaIMG.new("https://readmanganato.com/manga-db980758/chapter-51")
    manga.get_img
end