require 'selenium-webdriver'
require 'faraday'

url = "https://readmanganato.com/manga-db980758/chapter-51"

finalizado = false
contador = 1

#iniciar driver
driver = Selenium::WebDriver.for :firefox

driver.get url

def get_img(driver, global_count)
    imagenes = driver.find_elements(tag_name: 'img')
    index = 0
    imagenes.each do |img|
        img.save_screenshot("cap_#{global_count}_#{index}.png")
        index += 1
    end
end

# def save_img(driver, img_url, global_count)
#     img_url.length.times do |index|
#         response = Faraday.get(img_url[index],{},{})
#         File.open("#{global_count}_#{index}.jpg",'w') do |f|
#             f.puts response.body
#         end
#     end
# end

#obtener url
# puts 'Introduce la url:'
# url = gets.chomp

# informacion
puts "URL: #{driver.current_url}"
puts "Titulo: #{driver.title}"

get_img(driver,contador)
# avanzar a la siguiente pagina
# siguiente_boton = driver.find_element(link_text: 'NEXT CHAPTER').click
# if not siguiente_boton then
#     finalizado = true
# else
#     siguiente_boton.click
# end

contador += 1


