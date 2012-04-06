#!/usr/bin/env ruby

require 'rubygems'
require 'RMagick'

indir = Dir.open(ARGV[0]) if ARGV[0]
outdir = Dir.open(ARGV[1]) if ARGV[1]
if indir.nil? or indir.read.nil?
  puts "Please specify valid input directory"
  exit 
end

if outdir.nil? or outdir.read.nil?
  puts "Please specify valid output directory"
  exit 
end

while (fname = indir.read())
  next if fname =~ /cover/i
  if fname =~ /jpg/i
    img_name = ARGV[0] + "/" + fname
    resized_img_name = ARGV[1] + "/" + fname
    img = Magick::Image::read(img_name).first
    resized_img = img.resize_to_fit(img.columns/4, img.rows/4)
    resized_img.write(resized_img_name)
    puts fname
  end
end


