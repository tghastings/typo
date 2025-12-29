#!/usr/bin/env ruby

# Script to convert deprecated test assertions to modern RSpec syntax

Dir.glob("spec/**/*_spec.rb").each do |file|
  next if file.include?('backend_controller_spec.rb')

  content = File.read(file)
  original = content.dup

  # Convert assert_template to expect
  content.gsub!(/assert_template\s+(['"])(.+?)\1/, 'expect(response).to render_template(\1\2\1)')
  content.gsub!(/assert_template\s+:(\w+)/, 'expect(response).to render_template(:\1)')
  content.gsub!(/assert_template\s+(\w+)/, 'expect(response).to render_template(\1)')

  # Convert assert_response
  content.gsub!(/assert_response\s+:success/, 'expect(response).to be_successful')
  content.gsub!(/assert_response\s+:redirect(?:,\s*:action\s*=>\s*['"](\w+)['"])?/) do |match|
    if $1
      "expect(response).to redirect_to(action: '#{$1}')"
    else
      "expect(response).to be_redirect"
    end
  end

  # Convert assert_not_nil
  content.gsub!(/assert_not_nil\s+(.+?)$/) { "expect(#{$1}).not_to be_nil" }
  content.gsub!(/assert_not_nil\((.+?)\)/) { "expect(#{$1}).not_to be_nil" }

  # Convert assert_nil
  content.gsub!(/assert_nil\s+(.+?)$/) { "expect(#{$1}).to be_nil" }
  content.gsub!(/assert_nil\((.+?)\)/) { "expect(#{$1}).to be_nil" }

  # Convert assert
  content.gsub!(/assert\s+(.+?)\.valid\?/) { "expect(#{$1}).to be_valid" }
  content.gsub!(/assert\s+(.+?)$/) { "expect(#{$1}).to be_truthy" }

  # Convert assert_equal
  content.gsub!(/assert_equal\((.+?),\s*(.+?)\)/) { "expect(#{$2}).to eq(#{$1})" }
  content.gsub!(/assert_equal\s+(.+?),\s*(.+?)$/) { "expect(#{$2}).to eq(#{$1})" }

  # Convert assert_raise to expect { }.to raise_error
  content.gsub!(/assert_raise\((\w+(::\w+)?)\)\s*\{\s*(.+?)\s*\}/) { "expect { #{$3} }.to raise_error(#{$1})" }
  content.gsub!(/assert_raises?\((\w+(::\w+)?)\)\s*do\s*(.+?)\s*end/m) { "expect do\n#{$3}\nend.to raise_error(#{$1})" }

  # Only save if content changed
  if content != original
    File.write(file, content)
    puts "Updated: #{file}"
  end
end

puts "Done!"
