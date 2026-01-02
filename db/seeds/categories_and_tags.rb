# Create categories
categories = {
  'Education' => 'Academic and learning-related content',
  'Research' => 'PhD research and academic publications',
  'DevOps' => 'Docker, Kubernetes, and infrastructure topics',
  'Web Development' => 'Ruby on Rails, JavaScript, and web technologies',
  'Security' => 'Cybersecurity and privacy topics',
  'Tips & Tricks' => 'Quick tips and helpful guides'
}

created_categories = {}
categories.each do |name, description|
  cat = Category.find_or_create_by!(name: name)
  created_categories[name] = cat
  puts "Category: #{name}"
end

# Create tags
tag_names = %w[
  ruby rails docker kubernetes phd security privacy
  education research devops infrastructure vim tips
  academic conferences publications network homelab
  javascript html css web automation gitlab github
  linux macos terminal tools productivity
]

created_tags = {}
tag_names.each do |name|
  tag = Tag.find_or_create_by!(name: name)
  created_tags[name] = tag
  puts "Tag: #{name}"
end

# Map articles to categories and tags based on content analysis
article_mappings = {
  'Welcome to Typo' => {
    categories: ['Web Development'],
    tags: ['rails', 'ruby', 'web']
  },
  'Towards Resilient Critical Infrastructures' => {
    categories: ['Research', 'Security'],
    tags: ['phd', 'security', 'research', 'academic', 'infrastructure']
  },
  'Network Resilience PhD Thesis' => {
    categories: ['Research', 'Education'],
    tags: ['phd', 'research', 'network', 'academic']
  },
  'Using Docker Compose' => {
    categories: ['DevOps'],
    tags: ['docker', 'devops', 'infrastructure']
  },
  'Docker and Kubernetes Setup' => {
    categories: ['DevOps'],
    tags: ['docker', 'kubernetes', 'devops', 'infrastructure']
  },
  'Kubernetes Homelab' => {
    categories: ['DevOps'],
    tags: ['kubernetes', 'homelab', 'devops', 'infrastructure']
  },
  'GitLab CI/CD Pipeline' => {
    categories: ['DevOps', 'Web Development'],
    tags: ['gitlab', 'devops', 'automation', 'infrastructure']
  },
  'GitHub Actions Workflow' => {
    categories: ['DevOps', 'Web Development'],
    tags: ['github', 'devops', 'automation']
  },
  'Vim Configuration Guide' => {
    categories: ['Tips & Tricks'],
    tags: ['vim', 'tools', 'productivity', 'terminal']
  },
  'Terminal Productivity Tips' => {
    categories: ['Tips & Tricks'],
    tags: ['terminal', 'productivity', 'tips', 'tools']
  },
  'Ruby on Rails Best Practices' => {
    categories: ['Web Development'],
    tags: ['ruby', 'rails', 'web']
  },
  'JavaScript Modern Features' => {
    categories: ['Web Development'],
    tags: ['javascript', 'web']
  },
  'CSS Grid and Flexbox' => {
    categories: ['Web Development'],
    tags: ['css', 'html', 'web']
  },
  'Linux Server Administration' => {
    categories: ['DevOps'],
    tags: ['linux', 'devops', 'infrastructure']
  },
  'macOS Development Setup' => {
    categories: ['Tips & Tricks'],
    tags: ['macos', 'tools', 'productivity']
  },
  'Security Best Practices' => {
    categories: ['Security'],
    tags: ['security', 'privacy']
  },
  'Privacy and Encryption' => {
    categories: ['Security'],
    tags: ['security', 'privacy']
  },
  'Academic Conference Tips' => {
    categories: ['Education', 'Research'],
    tags: ['academic', 'conferences', 'research', 'education']
  },
  'Research Publication Guide' => {
    categories: ['Education', 'Research'],
    tags: ['academic', 'publications', 'research', 'education']
  },
  'PhD Survival Guide' => {
    categories: ['Education'],
    tags: ['phd', 'education', 'academic']
  }
}

# Apply mappings to articles
Article.find_each do |article|
  mapping = article_mappings[article.title]

  if mapping
    # Add categories
    mapping[:categories].each do |cat_name|
      cat = created_categories[cat_name]
      if cat && !article.categories.include?(cat)
        article.categories << cat
        puts "Added category '#{cat_name}' to '#{article.title}'"
      end
    end

    # Add tags
    mapping[:tags].each do |tag_name|
      tag = created_tags[tag_name]
      if tag && !article.tags.include?(tag)
        article.tags << tag
        puts "Added tag '#{tag_name}' to '#{article.title}'"
      end
    end
  else
    # For articles not in mapping, try to auto-categorize based on content
    content = "#{article.title} #{article.body}".downcase

    if content.include?('docker') || content.include?('kubernetes') || content.include?('k8s')
      cat = created_categories['DevOps']
      article.categories << cat unless article.categories.include?(cat)
      article.tags << created_tags['docker'] if content.include?('docker') && !article.tags.include?(created_tags['docker'])
      article.tags << created_tags['kubernetes'] if (content.include?('kubernetes') || content.include?('k8s')) && !article.tags.include?(created_tags['kubernetes'])
      puts "Auto-categorized '#{article.title}' as DevOps"
    end

    if content.include?('rails') || content.include?('ruby')
      cat = created_categories['Web Development']
      article.categories << cat unless article.categories.include?(cat)
      article.tags << created_tags['rails'] if content.include?('rails') && !article.tags.include?(created_tags['rails'])
      article.tags << created_tags['ruby'] if content.include?('ruby') && !article.tags.include?(created_tags['ruby'])
      puts "Auto-categorized '#{article.title}' as Web Development"
    end

    if content.include?('phd') || content.include?('thesis') || content.include?('research')
      cat = created_categories['Research']
      article.categories << cat unless article.categories.include?(cat)
      article.tags << created_tags['research'] unless article.tags.include?(created_tags['research'])
      puts "Auto-categorized '#{article.title}' as Research"
    end

    if content.include?('security') || content.include?('privacy') || content.include?('encryption')
      cat = created_categories['Security']
      article.categories << cat unless article.categories.include?(cat)
      article.tags << created_tags['security'] unless article.tags.include?(created_tags['security'])
      puts "Auto-categorized '#{article.title}' as Security"
    end
  end

  article.save if article.changed?
end

puts "\nDone! Created #{Category.count} categories and #{Tag.count} tags."
puts "Articles with categories: #{Article.joins(:categories).distinct.count}"
puts "Articles with tags: #{Article.joins(:tags).distinct.count}"
