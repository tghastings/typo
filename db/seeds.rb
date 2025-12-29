# Basic seed data for Typo blog

# Create the blog
Blog.create!(id: 1, settings: {"canonical_server_url" => ""}, base_url: "http://localhost:3000/")

# Create a default category
Category.create!(id: 1, name: "General", permalink: "general", position: 1)

# Create profiles (modules should be an array)
Profile.create!(id: 1, label: "admin", modules: [:dashboard, :articles, :pages, :media, :feedback, :themes, :sidebar, :users, :settings, :profile, :seo], nicename: "Typo administrator")
Profile.create!(id: 2, label: "publisher", modules: [:dashboard, :articles, :media, :pages, :feedback, :profile], nicename: "Blog publisher")
Profile.create!(id: 3, label: "contributor", modules: [:dashboard, :profile], nicename: "Contributor")

# Create text filters
TextFilter.create!(description: "None", filters: "", id: 1, markup: "none", name: "none", params: "")
TextFilter.create!(description: "Markdown", filters: "", id: 2, markup: "markdown", name: "markdown", params: "")
TextFilter.create!(description: "Textile", filters: "", id: 5, markup: "textile", name: "textile", params: "")

puts "Database seeded successfully!"
puts "Visit /setup to create your admin user and configure the blog."
