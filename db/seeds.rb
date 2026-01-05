# frozen_string_literal: true

# Basic seed data for Typo blog

# Create the blog
Blog.find_or_create_by!(id: 1) do |blog|
  blog.settings = { 'canonical_server_url' => '' }
  blog.base_url = 'http://localhost:3000/'
end

# Create a default category
Category.find_or_create_by!(id: 1) do |category|
  category.name = 'General'
  category.permalink = 'general'
  category.position = 1
end

# Create profiles (modules should be an array)
Profile.find_or_create_by!(id: 1) do |profile|
  profile.label = 'admin'
  profile.modules = %i[dashboard articles pages media feedback themes sidebar users settings profile
                       seo]
  profile.nicename = 'Typo administrator'
end
Profile.find_or_create_by!(id: 2) do |profile|
  profile.label = 'publisher'
  profile.modules = %i[dashboard articles media pages feedback profile]
  profile.nicename = 'Blog publisher'
end
Profile.find_or_create_by!(id: 3) do |profile|
  profile.label = 'contributor'
  profile.modules = %i[dashboard profile]
  profile.nicename = 'Contributor'
end

# Create a test user (only in test environment for CI)
if Rails.env.test?
  User.find_or_create_by!(login: 'admin') do |user|
    user.email = 'admin@example.com'
    user.password = 'password123'
    user.profile_id = 1
    user.name = 'Test Admin'
    user.state = 'active'
  end
  puts 'Test admin user created'
end

# Create text filters
TextFilter.find_or_create_by!(id: 1) do |tf|
  tf.description = 'None'
  tf.filters = ''
  tf.markup = 'none'
  tf.name = 'none'
  tf.params = ''
end
TextFilter.find_or_create_by!(id: 2) do |tf|
  tf.description = 'Markdown'
  tf.filters = ''
  tf.markup = 'markdown'
  tf.name = 'markdown'
  tf.params = ''
end
TextFilter.find_or_create_by!(id: 3) do |tf|
  tf.description = 'Markdown with SmartyPants'
  tf.filters = ['smartypants']
  tf.markup = 'markdown'
  tf.name = 'markdown smartypants'
  tf.params = ''
end
TextFilter.find_or_create_by!(id: 5) do |tf|
  tf.description = 'Textile'
  tf.filters = ''
  tf.markup = 'textile'
  tf.name = 'textile'
  tf.params = ''
end

puts 'Database seeded successfully!'
puts 'Visit /setup to create your admin user and configure the blog.'

# Load additional seed files from db/seeds directory
Dir[Rails.root.join('db', 'seeds', '*.rb')].each do |file|
  puts "Loading seed file: #{File.basename(file)}"
  load file
end
