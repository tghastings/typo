#!/usr/bin/env ruby

# Script to convert .should/.should_not to expect() syntax

Dir.glob("spec/**/*_spec.rb").each do |file|
  next if file.include?('backend_controller_spec.rb')

  content = File.read(file)
  original = content.dup

  # Convert .should be_* patterns
  content.gsub!(/(\w+)\.should\s+be_(\w+)/) { "expect(#{$1}).to be_#{$2}" }
  content.gsub!(/(\w+)\.should_not\s+be_(\w+)/) { "expect(#{$1}).not_to be_#{$2}" }

  # Convert assigns(:var).should patterns
  content.gsub!(/assigns\((.+?)\)\.should\s+be_(\w+)/) { "expect(assigns(#{$1})).to be_#{$2}" }
  content.gsub!(/assigns\((.+?)\)\.should_not\s+be_(\w+)/) { "expect(assigns(#{$1})).not_to be_#{$2}" }

  # Convert .should == patterns
  content.gsub!(/(\w+)\.should\s+==\s+(.+?)$/) { "expect(#{$1}).to eq(#{$2})" }
  content.gsub!(/assigns\((.+?)\)\.should\s+==\s+(.+?)$/) { "expect(assigns(#{$1})).to eq(#{$2})" }

  # Convert .should_not == patterns
  content.gsub!(/(\w+)\.should_not\s+==\s+(.+?)$/) { "expect(#{$1}).not_to eq(#{$2})" }
  content.gsub!(/assigns\((.+?)\)\.should_not\s+==\s+(.+?)$/) { "expect(assigns(#{$1})).not_to eq(#{$2})" }

  # Convert .should have_selector
  content.gsub!(/(\w+)\.should\s+have_selector\((.+?)\)/) { "expect(#{$1}).to have_selector(#{$2})" }
  content.gsub!(/(\w+)\.should_not\s+have_selector\((.+?)\)/) { "expect(#{$1}).not_to have_selector(#{$2})" }

  # Convert response.should patterns
  content.gsub!(/response\.should\s+be_(\w+)/) { "expect(response).to be_#{$1}" }
  content.gsub!(/response\.should_not\s+be_(\w+)/) { "expect(response).not_to be_#{$1}" }
  content.gsub!(/response\.should\s+render_template\((.+?)\)/) { "expect(response).to render_template(#{$1})" }
  content.gsub!(/response\.should\s+redirect_to\((.+?)\)/) { "expect(response).to redirect_to(#{$1})" }
  content.gsub!(/response\.should\s+have_selector\((.+?)\)/) { "expect(response).to have_selector(#{$1})" }
  content.gsub!(/response\.should_not\s+have_selector\((.+?)\)/) { "expect(response).not_to have_selector(#{$1})" }

  # Convert .status.should patterns
  content.gsub!(/response\.status\.should\s+==\s+(.+?)$/) { "expect(response.status).to eq(#{$1})" }

  # Convert lambda/proc patterns
  content.gsub!(/lambda\s+do\s*$/) { "expect do" }
  content.gsub!(/end\.should\s+raise_error\((.+?)\)/) { "end.to raise_error(#{$1})" }

  # Convert .should include
  content.gsub!(/(\w+)\.should\s+include\((.+?)\)/) { "expect(#{$1}).to include(#{$2})" }
  content.gsub!(/assigns\((.+?)\)\.should\s+include\((.+?)\)/) { "expect(assigns(#{$1})).to include(#{$2})" }

  # Only save if content changed
  if content != original
    File.write(file, content)
    puts "Updated: #{file}"
  end
end

puts "Done!"
