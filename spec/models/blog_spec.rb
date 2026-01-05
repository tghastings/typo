# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blog, type: :model do
  describe 'validations' do
    it 'validates presence of blog_name' do
      blog = Blog.new(base_url: 'http://example.com')
      blog.settings = { 'blog_name' => '' }
      blog.blog_name = ''
      expect(blog).not_to be_valid
      expect(blog.errors[:blog_name]).to include("can't be blank")
    end

    it 'validates only one blog can exist' do
      create(:blog)
      blog2 = Blog.new(base_url: 'http://another.com', blog_name: 'Another Blog')
      expect(blog2).not_to be_valid
      expect(blog2.errors[:base]).to include('There can only be one...')
    end

    it 'validates permalink_format contains %title%' do
      blog = create(:blog)
      blog.permalink_format = '/%year%/%month%/'
      expect(blog).not_to be_valid
      expect(blog.errors[:permalink_format]).to include('You need a permalink format with an identifier : %title%')
    end

    it 'validates permalink_format does not end in .atom' do
      blog = create(:blog)
      blog.permalink_format = '/%title%.atom'
      expect(blog).not_to be_valid
      expect(blog.errors[:permalink_format]).to include("Can't end in .rss or .atom. These are reserved to be used for feed URLs")
    end

    it 'validates permalink_format does not end in .rss' do
      blog = create(:blog)
      blog.permalink_format = '/%title%.rss'
      expect(blog).not_to be_valid
    end
  end

  describe '.default' do
    it 'returns the first blog by id' do
      blog = create(:blog)
      expect(Blog.default).to eq(blog)
    end

    it 'returns nil when no blogs exist' do
      Blog.delete_all
      expect(Blog.default).to be_nil
    end
  end

  describe '#configured?' do
    it 'returns true when blog_name is set in settings' do
      blog = create(:blog)
      expect(blog.configured?).to be true
    end

    it 'returns false when blog_name is not in settings' do
      Blog.delete_all
      blog = Blog.new(base_url: 'http://example.com')
      blog.settings = {}
      blog.save(validate: false)
      expect(blog.configured?).to be false
    end
  end

  describe '#global_pings_enabled?' do
    it 'returns true when global_pings_disable is false' do
      blog = create(:blog)
      blog.global_pings_disable = false
      expect(blog.global_pings_enabled?).to be true
    end

    it 'returns false when global_pings_disable is true' do
      blog = create(:blog)
      blog.global_pings_disable = true
      expect(blog.global_pings_enabled?).to be false
    end
  end

  describe '#url_for' do
    let(:blog) { create(:blog, base_url: 'http://myblog.net') }

    it 'generates URL from string path' do
      expect(blog.url_for('articles')).to eq('http://myblog.net/articles')
    end

    it 'generates URL with anchor' do
      expect(blog.url_for('articles', anchor: 'comments')).to eq('http://myblog.net/articles#comments')
    end

    it 'generates path only when only_path is true' do
      expect(blog.url_for('articles', only_path: true)).to eq('/articles')
    end
  end

  describe '#file_url' do
    it 'generates URL for static files' do
      blog = create(:blog, base_url: 'http://myblog.net')
      expect(blog.file_url('image.jpg')).to eq('http://myblog.net/files/image.jpg')
    end
  end

  describe '#root_path' do
    it 'returns empty string for base_url without path' do
      blog = create(:blog, base_url: 'http://myblog.net')
      expect(blog.root_path).to eq('')
    end

    it 'returns path for base_url with subpath' do
      blog = create(:blog, base_url: 'http://myblog.net/blog')
      expect(blog.root_path).to eq('/blog')
    end
  end

  describe '#rss_limit_params' do
    it 'returns limit hash when limit_rss_display is set' do
      blog = create(:blog, limit_rss_display: 15)
      expect(blog.rss_limit_params).to eq({ limit: 15 })
    end

    it 'returns empty hash when limit_rss_display is zero' do
      blog = create(:blog, limit_rss_display: 0)
      expect(blog.rss_limit_params).to eq({})
    end
  end

  describe 'settings' do
    let(:blog) { create(:blog) }

    it 'has default blog_name' do
      Blog.delete_all
      new_blog = Blog.new(base_url: 'http://example.com')
      expect(new_blog.blog_name).to eq('My Shiny Weblog!')
    end

    it 'can set and get blog_subtitle' do
      blog.blog_subtitle = 'A great blog'
      blog.save
      expect(blog.reload.blog_subtitle).to eq('A great blog')
    end

    it 'has default limit_article_display of 10' do
      Blog.delete_all
      new_blog = Blog.new(base_url: 'http://example.com')
      expect(new_blog.limit_article_display).to eq(10)
    end

    it 'has default theme of scribbish' do
      Blog.delete_all
      new_blog = Blog.new(base_url: 'http://example.com')
      expect(new_blog.theme).to eq('scribbish')
    end

    it 'has default allow_comments of true' do
      Blog.delete_all
      new_blog = Blog.new(base_url: 'http://example.com')
      expect(new_blog.default_allow_comments).to be true
    end
  end

  describe '#requested_article' do
    it 'finds article by params hash' do
      blog = create(:blog)
      article = create(:article, published_at: Time.zone.local(2024, 1, 15))
      params = {
        year: '2024',
        month: '01',
        day: '15',
        title: article.permalink
      }
      expect(blog.requested_article(params)).to eq(article)
    end
  end

  describe '#articles_matching' do
    it 'searches articles by query' do
      blog = create(:blog)
      article = create(:article, body: 'This is about Ruby programming')
      results = blog.articles_matching('Ruby')
      expect(results).to include(article)
    end
  end
end
