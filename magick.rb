#!/usr/bin/env ruby

require 'rubygems'
require 'rdiscount'
require 'RMagick'

data = File.read(ARGV[0] || 'book.text')

def create_toc_html(toc) 
  file = File.open('toc.html','w')
  file.puts("<h1><a name='TOC'><center>TABLE OF CONTENTS</center></a></h1>")
  h1_count = h2_count = recipe_count = 1
  toc.each do |h1|
    file.puts("<div class='toc_h1'><a href='#ch_h1_#{h1_count}'>#{h1[:title]}</a></div>")
    h1_count += 1
    is_recipe = h1[:title] =~ /phase/i
    if h1[:subheading].length > 0
      file.puts("<blockquote>")
      h1[:subheading].each do |h2|
        if (is_recipe)
          file.puts("    <div class='toc_h2'><a href='#ch_#{h2_count}'>#{recipe_count}. #{h2}</a></div>")
          recipe_count += 1
        else
          file.puts("    <div class='toc_h2'><a href='#ch_#{h2_count}'>#{h2}</a></div>")
        end
        h2_count += 1
      end
      file.puts("</blockquote>")
    end
  end
  file.close
end

def create_toc_ncx(toc)
  file = File.open('toc.ncx','w')
  file.puts("<ncx>")
  file.puts("<navMap>")
  h1_count = h2_count = play_order = recipe_count = 1
  toc.each do |h1|
    title = h1[:title].gsub(/<.*?>/,'')
    is_recipe = h1[:title] =~ /phase/i
    file.puts <<EOF
  <navPoint class="titlepage" id="L#{h1_count}T" playOrder="#{play_order}">
    <navLabel><text>#{title}</text></navLabel>
    <content src="book.html#ch_h1_#{h1_count}" />
EOF
    h1_count += 1
    play_order += 1
   
    h1[:subheading].each do |h2|
      _prefix = ""
      if is_recipe
        _prefix = "#{recipe_count}. "
        recipe_count += 1
      end
      file.puts <<EOF
    <navPoint class="chapter" id="level2-chap#{h2_count}" playOrder="#{play_order}">
      <navLabel><text>#{_prefix}#{h2}</text></navLabel>
      <content src="book.html#ch_#{h2_count}" />
    </navPoint>
EOF
      h2_count += 1
      play_order += 1
    end

    file.puts("  </navPoint>")
  end 
  file.puts("</navMap>")
  file.puts("</ncx>")
end

html_data = RDiscount.new(data).to_html
new_lines = []
dir_exists = false
if File.exists?("c")
  dir_exists = true
else 
  Dir.mkdir("c")
end

toc = []
last_item = nil
html_data.lines.each do |l|
  if l =~ /<h1>(.*)<\/h1>/i
    _title = $~[1]
    last_item = {:title => _title, :subheading => []}
    toc << last_item
  elsif l =~ /<h2>(.*)<\/h2>/i
    _title = $~[1]
    last_item[:subheading] << _title
  end
end

create_toc_html(toc)
create_toc_ncx(toc)

h1_count = h2_count = recipe_count = 1
recipe_started = false

html_data.lines.each do |l|
  if l =~ /<h1>(.*)<\/h1>/i
    _title = $~[1]
    recipe_started = _title =~ /phase/i
    new_lines << "<h1><a name='ch_h1_#{h1_count}'>#{_title}</a></h1>"
    h1_count += 1
  elsif l =~ /<h2>(.*)<\/h2>/i
    _title = $~[1]
    if recipe_started
      new_lines << "<h2><a name='ch_#{h2_count}'>#{recipe_count}. #{_title}</a></h2>"
      recipe_count += 1
    else
      new_lines << "<h2><a name='ch_#{h2_count}'>#{_title}</a></h2>"
    end
    h2_count += 1
  #elsif l =~ /blockquote.*nutrition/
  #  new_lines << "<h4>Nutritional Facts</h4>"
  #  new_lines << l
  #elsif l =~ /<blockquote>/
  #  l = l.sub(/<blockquote>/,"<blockquote class='info'>")
  #  new_lines << "<h4>Please Note</h4>"
  #  new_lines << l
  else
    new_lines << l
  end
end

if File.exists?('toc.html')
  toc = File.read('toc.html')
else
  puts "Could not find table of contents file toc.html aborting"
  exit 1
end

file = File.open('book.html','w')
file.puts <<EOF
<html>
  <head>
     <title>Baby Food Recipe</title>
     <link rel="stylesheet" href="style.css" type="text/css" media="all">
  <body>
    #{new_lines.join("\n").sub(/TABLE_OF_CONTENTS/,toc)}
  </body>
</html>
EOF
file.close

