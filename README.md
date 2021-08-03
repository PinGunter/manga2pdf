# manga2pdf
Simple script to download and merge manga images into a single pdf file. Uses Ruby and Selenium.
It's currently WIP and in a very early stage.

### Requirements
* Ruby 2.7
* selenium-webdriver 4.0 (currently in beta)
* firefox-geckodriverd

### Usage
Launch the script like this:
```bash
ruby manga2pdf.rb -u <url> [-d]
```
* -u is for the url 
* -d is to create individual directories for each volume.
