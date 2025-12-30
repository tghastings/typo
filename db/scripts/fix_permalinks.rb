#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/../../config/environment'
Article.all.each do |a|
  (puts "Processing #{a.title} (#{a.stripped_title})" ; a.save)  if a.permalink.blank?
end
