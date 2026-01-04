#!/usr/bin/env ruby
# frozen_string_literal: true

require "#{File.dirname(__FILE__)}/../../config/environment"
Article.all.each do |a|
  if a.permalink.blank?
    (puts "Processing #{a.title} (#{a.stripped_title})"
     a.save)
  end
end
