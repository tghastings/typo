#!/usr/bin/env ruby

# Script to convert bare should/should_not to is_expected syntax

Dir.glob("spec/**/*_spec.rb").each do |file|
  next if file.include?('backend_controller_spec.rb')

  content = File.read(file)
  original = content.dup

  # Convert bare should patterns (with implicit subject)
  # These are typically used when there's a subject { } block
  content.gsub!(/^(\s+)should\s+([^\s].+)$/) { "#{$1}is_expected.to #{$2}" }
  content.gsub!(/^(\s+)should_not\s+([^\s].+)$/) { "#{$1}is_expected.not_to #{$2}" }

  # Fix view.should patterns that weren't caught before
  content.gsub!(/view\.should\s+render_template\((.+?)\)/) { "expect(view).to render_template(#{$1})" }
  content.gsub!(/view\.should_not\s+render_template\((.+?)\)/) { "expect(view).not_to render_template(#{$1})" }

  # Only save if content changed
  if content != original
    File.write(file, content)
    puts "Updated: #{file}"
  end
end

puts "Done!"
